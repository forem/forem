module Api
  module V1
    # @note This controller partially authorizes with the ArticlePolicy, in an ideal world, it would
    #       fully authorize.  However, that refactor would require significantly more work.
    class ArticlesController < ApiController
      include Api::ArticlesController

      before_action :authenticate_with_api_key!, only: %i[create update me unpublish semantic_search]
      before_action :validate_article_param_is_hash, only: %i[create update]
      before_action :set_cache_control_headers, only: %i[index show show_by_slug search]
      after_action :verify_authorized, only: %i[create]

      PARALLEL_FETCH_TIMEOUT_SECONDS = 1.2
      INITIAL_CANDIDATE_LIMIT = 250
      JEV_SHORTLIST_SIZE = Ai::SearchReranker::SHORTLIST_LIMIT
      EMBEDDING_BASELINE_SIMILARITY = 0.50
      HIGH_DISTANCE_PENALTY_THRESHOLD = 0.45
      HYDRATION_COLUMNS = (Api::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION + [:score]).uniq.freeze

      STOP_WORDS = Set.new(
        %w[
          a about above after again against all am an and any are aren't as at be because been before being below
          between both but by can't cannot couldn't did didn't do does doesn't doing don't down during each few
          for from further had hadn't has hasn't have haven't having he he'd he'll he's her here here's hers
          herself him himself his how how's i i'd i'll i'm i've if in into is isn't it it's its itself let's
          me more most mustn't my myself no nor not of off on once only or other ought our ours ourselves out
          over own same shan't she she'd she'll she's should shouldn't so some such than that that's the their
          theirs them themselves then there there's these they they'd they'll they're they've this those through
          to too under until up very was wasn't we we'd we'll we're we've were weren't what what's whatever when
          when's where where's which while who who's whom why why's with won't would wouldn't you you'd you'll
          you're you've your yours yourself yourselves
        ],
      ).freeze

      def semantic_search
        query_text = params[:q]
        if query_text.blank?
          render json: { error: "q parameter is required" }, status: :bad_request
          return
        end

        per_page = [params.fetch(:per_page, 30).to_i, 100].min
        per_page = [per_page, 1].max
        page = [params[:page].to_i, 1].max
        candidate_limit = [per_page * 3, INITIAL_CANDIDATE_LIMIT].max
        cleaned_query = clean_keyword_query(query_text)

        # Stage 1: Broad parallel fetch (Algolia + Query Embedding) with 1.2s timeout
        quoted_vector, algolia_ids = fetch_candidates_and_embedding_in_parallel(
          query_text,
          cleaned_query,
          candidate_limit,
        )

        if algolia_ids.any?
          # Stage 2 & 3: Calibrated hybrid pre-ranking + Jev re-ranking on top 50 shortlist
          ordered_articles = prerank_and_rerank_algolia_candidates(algolia_ids, query_text, quoted_vector)
          paginated_articles = ordered_articles[((page - 1) * per_page)...(page * per_page)] || []
          paginated_articles = verify_published_articles(paginated_articles)

          render json: serialize_semantic_search_articles(paginated_articles)
          return
        end

        # Fallback to Database Hybrid Search (requires query embedding)
        if quoted_vector.nil?
          render json: { error: "Failed to generate search embedding" }, status: :service_unavailable
          return
        end

        ordered_articles = search_and_rerank_database_candidates(
          query_text,
          cleaned_query,
          quoted_vector,
          candidate_limit,
          page: page,
          per_page: per_page,
        )
        ordered_articles = verify_published_articles(ordered_articles)

        render json: serialize_semantic_search_articles(ordered_articles)
      end

      private

      # Runs Algolia HTTP search in a pure-HTTP background thread while computing the query
      # embedding on the main thread. All Settings, ApplicationConfig, RequestStore, Rails.cache,
      # and ActiveRecord calls stay strictly on the main thread to prevent DB/threading issues.
      def fetch_candidates_and_embedding_in_parallel(query_text, cleaned_query, candidate_limit)
        algolia_ready = algolia_available?
        algolia_query = cleaned_query.presence || query_text
        search_params = algolia_ready ? build_algolia_search_params(cleaned_query, candidate_limit) : nil

        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        algolia_thread = if algolia_ready
                           Thread.new(algolia_query, search_params) do |q, params_hash|
                             raw_res = Article.raw_search(q, params_hash)
                             hits = raw_res.is_a?(Hash) ? raw_res["hits"].to_a : []
                             { ids: hits.map { |hit| hit["objectID"].to_i }, error: nil }
                           rescue StandardError => e
                             { ids: [], error: e.message }
                           end
                         end

        quoted_vector = fetch_quoted_query_vector(query_text)
        algolia_ids = resolve_algolia_thread(algolia_thread, started_at)

        [quoted_vector, algolia_ids]
      end

      def algolia_available?
        env_configured = ApplicationConfig["ALGOLIA_APPLICATION_ID"].present? &&
          ApplicationConfig["ALGOLIA_API_KEY"].present?
        settings_configured = Settings::General.algolia_application_id.present? &&
          Settings::General.algolia_api_key.present?

        (env_configured || settings_configured) && Settings::General.algolia_search_enabled?
      end

      def build_algolia_search_params(cleaned_query, candidate_limit)
        cleaned_words = cleaned_query.to_s.split
        search_params = {
          hitsPerPage: candidate_limit,
          facetFilters: [],
          removeStopWords: true,
          ignorePlurals: true,
          advancedSyntax: true,
          distinct: true,
          typoTolerance: true,
          minWordSizefor1Typo: 5,
          minWordSizefor2Typos: 9,
          removeWordsIfNoResults: "allOptional",
          restrictSearchableAttributes: %w[title tag_list body]
        }
        search_params[:optionalWords] = cleaned_words if cleaned_words.size > 1

        subforem_id = RequestStore.store[:subforem_id]
        search_params[:facetFilters] << "subforem_id:#{subforem_id}" if subforem_id.present?
        search_params
      end

      def fetch_quoted_query_vector(query_text)
        query_hash = Digest::SHA256.hexdigest(query_text)
        embedding = Rails.cache.fetch("semantic_search_embedding/#{query_hash}", expires_in: 1.hour) do
          Timeout.timeout(PARALLEL_FETCH_TIMEOUT_SECONDS) do
            Ai::Embedding.new(wrapper: self, timeout: PARALLEL_FETCH_TIMEOUT_SECONDS).call(
              query_text,
              task_type: "RETRIEVAL_QUERY",
              output_dimensionality: 768,
            )
          end
        end
        return if embedding.blank?

        vector_literal = "[#{embedding.to_a.join(',')}]"
        Article.connection.quote(vector_literal)
      rescue StandardError => e
        Rails.logger.error("Failed to generate embedding for article semantic search: #{e.message}")
        nil
      end

      def resolve_algolia_thread(algolia_thread, started_at)
        return [] unless algolia_thread

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
        remaining_timeout = [PARALLEL_FETCH_TIMEOUT_SECONDS - elapsed, 0.05].max

        if algolia_thread.join(remaining_timeout)
          result = algolia_thread.value
          if result[:error]
            Rails.logger.warn("Algolia search failed: #{result[:error]}. Falling back to DB search.")
            []
          else
            result[:ids]
          end
        else
          algolia_thread.kill
          Rails.logger.warn(
            "Algolia search timed out after #{PARALLEL_FETCH_TIMEOUT_SECONDS}s. Falling back to DB search.",
          )
          []
        end
      end

      def prerank_and_rerank_algolia_candidates(algolia_ids, query_text, quoted_vector)
        select_columns = HYDRATION_COLUMNS.map { |col| "articles.#{col}" }
        select_columns << "(semantic_embedding <=> #{quoted_vector}) AS distance" if quoted_vector.present?

        @articles = Article.published.from_subforem
          .where(id: algolia_ids)
          .where("score >= ?", Settings::UserExperience.index_minimum_score)
          .select(select_columns.join(", "))

        threshold_val = params[:threshold].present? ? params[:threshold].to_f : nil
        distance_rank_map = build_distance_rank_map(@articles, threshold_val)
        indexed_articles = @articles.index_by(&:id)
        now = Time.current

        scored_articles = algolia_ids.each_with_index.filter_map do |id, index|
          article = indexed_articles[id]
          score_algolia_candidate(article, index, distance_rank_map, threshold_val, now) if article
        end

        scored_articles.sort_by! { |_article, score| -score }

        Ai::SearchReranker.new(query: query_text, scored_articles: scored_articles).rerank
      end

      def build_distance_rank_map(articles, threshold_val)
        distinct_distances = articles.filter_map do |article|
          d = extract_distance(article)
          next if threshold_val && d && d > threshold_val

          d
        end.uniq.sort
        distinct_distances.each_with_index.to_h
      end

      def score_algolia_candidate(article, index, distance_rank_map, threshold_val, now)
        distance = extract_distance(article)
        return if threshold_val && distance && distance > threshold_val

        k = 60
        algolia_rrf = 1.0 / (k + index + 1)
        base_rrf = if distance
                     semantic_rank = distance_rank_map.fetch(distance, index)
                     semantic_rrf = 1.0 / (k + semantic_rank + 1)
                     (algolia_rrf + semantic_rrf) / 2.0
                   else
                     algolia_rrf
                   end

        composite_score = base_rrf *
          calibrated_semantic_multiplier(distance) *
          calculate_recency_multiplier(article.published_at, now) *
          calculate_quality_multiplier(article.score)

        [article, composite_score]
      end

      def search_and_rerank_database_candidates(
        query_text, cleaned_query, quoted_vector, candidate_limit, page:, per_page:
      )
        keyword_data, semantic_data = fetch_database_hybrid_candidates(cleaned_query, quoted_vector, candidate_limit)
        boosted_scores = compute_database_hybrid_scores(keyword_data, semantic_data)
        sorted_ids = boosted_scores.keys.sort_by { |id| -boosted_scores[id] }

        page_start = (page - 1) * per_page
        page_end = page * per_page
        use_jev_shortlist = page_start < JEV_SHORTLIST_SIZE && Ai::FunctionConfig.jev?(:semantic_search_reranking)
        ids_to_hydrate = if use_jev_shortlist
                           sorted_ids.first([JEV_SHORTLIST_SIZE, page_end].max)
                         else
                           sorted_ids[page_start...page_end] || []
                         end

        indexed_articles = hydrate_database_candidates(ids_to_hydrate, quoted_vector)
        if use_jev_shortlist
          scored_candidates = ids_to_hydrate.filter_map do |id|
            article = indexed_articles[id]
            [article, boosted_scores[id]] if article
          end
          reranked = Ai::SearchReranker.new(query: query_text, scored_articles: scored_candidates).rerank
          reranked[page_start...page_end] || []
        else
          ids_to_hydrate.filter_map { |id| indexed_articles[id] }
        end
      end

      def fetch_database_hybrid_candidates(cleaned_query, quoted_vector, candidate_limit)
        base_scope = Article.published.from_subforem
          .where("score >= ?", Settings::UserExperience.index_minimum_score)

        if params[:threshold].present?
          base_scope = base_scope
            .where.not(semantic_embedding: nil)
            .where("semantic_embedding <=> #{quoted_vector} <= ?", params[:threshold].to_f)
        end

        keyword_data = base_scope
          .search_articles(cleaned_query)
          .limit(candidate_limit)
          .pluck(:id, :score, :published_at)

        semantic_data = base_scope
          .where.not(semantic_embedding: nil)
          .order(Arel.sql("semantic_embedding <=> #{quoted_vector}"))
          .limit(candidate_limit)
          .pluck(:id, :score, :published_at)

        [keyword_data, semantic_data]
      end

      def hydrate_database_candidates(ids_to_hydrate, quoted_vector)
        return {} if ids_to_hydrate.empty?

        select_columns = HYDRATION_COLUMNS.map { |col| "articles.#{col}" }
        select_columns << "(semantic_embedding <=> #{quoted_vector}) AS distance"

        @articles = Article.published.from_subforem
          .select(select_columns.join(", "))
          .where(id: ids_to_hydrate)

        if params[:threshold].present?
          threshold_val = params[:threshold].to_f
          @articles = @articles.where("semantic_embedding <=> #{quoted_vector} <= ?", threshold_val)
        end

        @articles.index_by(&:id)
      end

      def compute_database_hybrid_scores(keyword_data, semantic_data)
        keyword_ids = []
        article_metadata = {}
        keyword_data.each do |(id, score, published_at)|
          keyword_ids << id
          article_metadata[id] = { score: score, published_at: published_at }
        end

        semantic_ids = []
        semantic_data.each do |(id, score, published_at)|
          semantic_ids << id
          article_metadata[id] ||= { score: score, published_at: published_at }
        end

        k = 60
        scores = Hash.new(0.0)
        keyword_ids.each_with_index { |id, index| scores[id] += 1.0 / (k + index + 1) }
        semantic_ids.each_with_index { |id, index| scores[id] += 1.0 / (k + index + 1) }

        now = Time.current
        scores.each_with_object({}) do |(id, rrf_score), boosted_scores|
          meta = article_metadata[id]
          next unless meta

          recency_multiplier = calculate_recency_multiplier(meta[:published_at], now)
          quality_multiplier = calculate_quality_multiplier(meta[:score])
          boosted_scores[id] = rrf_score * recency_multiplier * quality_multiplier
        end
      end

      def calibrated_semantic_multiplier(distance)
        return 1.0 unless distance

        raw_similarity = [1.0 - distance, 0.0].max
        calibrated_sim = [
          (raw_similarity - EMBEDDING_BASELINE_SIMILARITY) / (1.0 - EMBEDDING_BASELINE_SIMILARITY),
          0.0,
        ].max
        multiplier = 1.0 + (1.5 * calibrated_sim)
        distance > HIGH_DISTANCE_PENALTY_THRESHOLD ? (multiplier * 0.65) : multiplier
      end

      def calculate_recency_multiplier(published_at, now)
        days_ago = [(now - (published_at || now)) / 1.day, 0.0].max
        recency_score = 1.0 / ((days_ago / 30.0) + 1.0)
        1.0 + (0.6 * recency_score)
      end

      def calculate_quality_multiplier(score)
        score_val = [score.to_f, 0.0].max
        1.0 + (0.1 * Math.log(score_val + 1.0))
      end

      def extract_distance(article)
        article.respond_to?(:distance) && article.distance ? article.distance.to_f : nil
      end

      def serialize_semantic_search_articles(articles)
        articles.map do |article|
          distance = extract_distance(article)
          similarity = distance ? (1.0 - distance).round(6) : nil
          article.as_json(only: Api::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION).merge(
            "distance" => distance,
            "similarity" => similarity,
          )
        end
      end

      def clean_keyword_query(query_text)
        return "" if query_text.blank?

        # Remove common English contraction endings (e.g. 's, 't, 'd, 're, 've, 'll, 'm)
        cleaned = query_text.downcase.gsub(/'(s|t|d|re|ve|ll|m)\b/, "")
        # Extract alphanumeric tokens along with trailing +/# symbols (e.g. c++, c#, f#)
        # while preserving single-letter technical terms (e.g. c, r) that aren't stop words.
        words = cleaned.scan(/[a-z0-9]+[+#]*/)
        cleaned_words = words.reject { |w| STOP_WORDS.include?(w) }

        cleaned_words.empty? ? query_text : cleaned_words.join(" ")
      end

      # Efficient final verification step to ensure candidate articles still exist
      # in the database and are currently published (guards against external index drift).
      def verify_published_articles(articles)
        return [] if articles.blank?

        candidate_ids = articles.filter_map(&:id)
        return [] if candidate_ids.blank?

        valid_ids = Article.published.from_subforem.where(id: candidate_ids).ids.to_set
        articles.select { |article| valid_ids.include?(article.id) && article.published? }
      end
    end
  end
end
