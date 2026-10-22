module Ai
  ##
  # Re-ranks a shortlist of candidate articles against a search query using TypeSafe Jev.
  #
  # In the 3-stage semantic search pipeline:
  #   1. Broad parallel candidate sweep (Algolia + query embedding with a 1.2s timeout)
  #   2. Calibrated hybrid pre-ranking (lexical RRF + semantic distance RRF + cosine + recency/quality)
  #   3. Jev re-ranking of the top 50 shortlist candidates in a single batched evaluation call.
  #
  # Runs only when the :semantic_search_reranking function is set to Jev (see Ai::FunctionConfig);
  # otherwise or on timeout/error, fails open and preserves the Stage 2 pre-ranked order.
  class SearchReranker
    include Ai::TypeSafe::Questions

    VERSION = "1.0".freeze
    FUNCTION_KEY = :semantic_search_reranking

    SHORTLIST_LIMIT = 50
    TIMEOUT_SECONDS = 1.2
    FAIL_FAST = { timeout: TIMEOUT_SECONDS, max_retries: 0 }.freeze

    JEV_WEIGHT = 0.80
    PRE_RANK_WEIGHT = 0.20

    MAX_QUERY_LENGTH = 500
    MAX_TITLE_LENGTH = 200
    MAX_DESCRIPTION_LENGTH = 300

    # @param query [String] The raw user search query
    # @param scored_articles [Array<Array(Article, Float)>] Pre-ranked [article, score] pairs sorted descending
    def initialize(query:, scored_articles:)
      @query = query.to_s.strip.first(MAX_QUERY_LENGTH)
      @scored_articles = Array(scored_articles)
    end

    # @return [Array<Article>] Articles ordered by combined Jev + pre-rank score (for top 50) followed by remainder
    def rerank
      return default_order if @query.blank? || @scored_articles.size <= 1

      selection = Ai::FunctionConfig.selection_for(FUNCTION_KEY)
      return default_order unless selection.jev?

      shortlist = @scored_articles.first(SHORTLIST_LIMIT)
      remainder = @scored_articles.drop(SHORTLIST_LIMIT)

      probabilities = fetch_jev_probabilities(shortlist.map(&:first), selection.model)
      return default_order if probabilities.blank?

      combine_scores(shortlist, probabilities) + remainder.map(&:first)
    rescue StandardError => e
      Rails.logger.warn("Ai::SearchReranker failed: #{e.message}. Falling back to pre-ranked order.")
      default_order
    end

    private

    def default_order
      @scored_articles.map(&:first)
    end

    def combine_scores(shortlist, probabilities)
      max_pre_score = shortlist.map { |_article, score| score.to_f }.max.to_f

      reranked = shortlist.each_with_index.map do |(article, pre_score), index|
        norm_pre_score = max_pre_score.positive? ? (pre_score.to_f / max_pre_score) : 0.0
        jev_prob = probabilities.fetch(article.id, norm_pre_score).to_f
        combined_score = (JEV_WEIGHT * jev_prob) + (PRE_RANK_WEIGHT * norm_pre_score)
        [article, combined_score, index]
      end

      reranked.sort_by { |_article, score, index| [-score, index] }.map(&:first)
    end

    def fetch_jev_probabilities(articles, model)
      cache_digest = Digest::SHA256.hexdigest(
        [
          VERSION,
          model,
          @query,
          articles.map { |a| "#{a.id}:#{a.updated_at.to_i}" }.join(","),
        ].join("/"),
      )

      Rails.cache.fetch("semantic_search_jev_rerank/#{cache_digest}", expires_in: 1.hour) do
        questions = build_questions(articles)
        client = Ai::TypeSafe::Client.new(model: model, wrapper: self, **FAIL_FAST)
        result = client.evaluate(state: { query: @query }, questions: questions)

        articles.each_with_object({}) do |article, memo|
          memo[article.id] = result.noul("candidate::#{article.id}")
        end
      end
    end

    def build_questions(articles)
      articles.each_with_object({}) do |article, questions|
        questions["candidate::#{article.id}"] = noul(
          {
            candidate: {
              title: article.title.to_s.first(MAX_TITLE_LENGTH),
              tags: article.cached_tag_list.presence,
              description: article.description.to_s.first(MAX_DESCRIPTION_LENGTH).presence
            }.compact,
            question: "Does `candidate` directly address, explain, or provide useful developer experience for `query`?"
          },
          yes: "Its primary topic, technology, or problem matches `query` and provides substantive technical value.",
          no: "It is about an unrelated topic, only mentions a term from `query` in passing, " \
              "or matches by superficial word overlap.",
        )
      end
    end
  end
end
