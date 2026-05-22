module Ai
  class TrendDetector
    VERSION = "1.0".freeze

    def initialize
      @ai_client = Ai::Base.new(wrapper: self)
    end

    def call(days_lookback: 7, similarity_threshold: 0.90, match_threshold: 0.98, min_articles: 10, min_score: nil)
      min_score ||= Settings::UserExperience.index_minimum_score.to_i

      articles = Article.published
                        .where("published_at >= ?", days_lookback.days.ago)
                        .where("score >= ?", min_score)
                        .where.not(semantic_embedding: nil)
                        .order(score: :desc)
                        .limit(1000)
                        .to_a

      return if articles.empty?

      # Group articles into clusters using Leader Clustering
      # Similarity threshold 0.85 means distance <= 0.15
      dist_threshold = 1.0 - similarity_threshold
      clusters = []

      articles.each do |article|
        article_vec = article.semantic_embedding.to_a
        next unless article_vec.length == 768

        best_cluster = nil
        min_dist = 2.0 # Cosine distance is in range [0, 2]

        clusters.each do |c|
          dist = cosine_distance(c[:centroid], article_vec)
          if dist <= dist_threshold
            best_cluster = c
            min_dist = dist
            break
          elsif dist < min_dist
            min_dist = dist
            best_cluster = c
          end
        end

        if min_dist <= dist_threshold && best_cluster
          # Incremental centroid update: (old_centroid * N + new_vector) / (N + 1)
          n = best_cluster[:articles].length
          best_cluster[:centroid] = best_cluster[:centroid].zip(article_vec).map do |c_val, a_val|
            (c_val * n + a_val) / (n + 1)
          end
          best_cluster[:articles] << article
        else
          clusters << { centroid: article_vec, articles: [article] }
        end
      end

      # Filter clusters: must have at least min_articles articles, sorted by size descending, limit to top 5
      valid_clusters = clusters.select { |c| c[:articles].length >= min_articles }
                               .sort_by { |c| -c[:articles].length }
                               .first(5)

      # Process each valid cluster
      valid_clusters.each do |cluster|
        # Sort articles by score (hotness) descending
        cluster[:articles].sort_by! { |a| -a.score }

        # Check if this cluster matches an existing active trend in the DB
        # Match threshold 0.88 means distance <= 0.12
        existing_trend = find_matching_trend(cluster[:centroid], 1.0 - match_threshold, days_lookback: days_lookback)

        # Build prompt and call Gemini to get trend metadata (name, description, key questions)
        metadata = generate_trend_metadata(cluster[:articles].first(5))
        next if metadata.blank?

        trend = nil
        new_trend_created = false

        Trend.transaction do
          if existing_trend
            existing_trend.update!(
              name: metadata["name"],
              description: metadata["description"],
              key_questions: metadata["key_questions"],
              centroid_embedding: cluster[:centroid],
              last_observed_at: Time.current
            )
            trend = existing_trend
          else
            trend = Trend.create!(
              name: metadata["name"],
              description: metadata["description"],
              key_questions: metadata["key_questions"],
              centroid_embedding: cluster[:centroid],
              first_observed_at: Time.current,
              last_observed_at: Time.current
            )
            new_trend_created = true
          end

          # Sync memberships
          active_article_ids = cluster[:articles].map(&:id)
          trend.trend_memberships.where.not(article_id: active_article_ids).destroy_all

          cluster[:articles].each do |article|
            dist = cosine_distance(trend.centroid_embedding.to_a, article.semantic_embedding.to_a)
            membership = trend.trend_memberships.find_or_initialize_by(article: article)
            membership.distance = dist
            membership.save!
          end

          # Recalculate trend score
          recalculate_trend_score(trend, days_lookback: days_lookback)
        end

        if new_trend_created && trend
          Trends::GenerateCoverImageWorker.perform_async(trend.id)
        end
      end
    end

    private

    def cosine_distance(vec_a, vec_b)
      dot_product = 0.0
      mag_a = 0.0
      mag_b = 0.0

      vec_a.zip(vec_b).each do |a, b|
        dot_product += a * b
        mag_a += a * a
        mag_b += b * b
      end

      return 1.0 if mag_a == 0.0 || mag_b == 0.0

      similarity = dot_product / (Math.sqrt(mag_a) * Math.sqrt(mag_b))
      1.0 - similarity
    end

    def calculate_centroid(articles)
      vectors = articles.map { |a| a.semantic_embedding.to_a }
      dimension = vectors.first.length
      sum_vector = Array.new(dimension, 0.0)

      vectors.each do |v|
        v.each_with_index { |val, idx| sum_vector[idx] += val }
      end

      sum_vector.map { |val| val / vectors.length }
    end

    def find_matching_trend(centroid, max_distance, days_lookback:)
      centroid_literal = "[#{centroid.join(',')}]"
      # Order by pgvector cosine distance operator, filtering to active trends
      trend = Trend.where("last_observed_at >= ?", days_lookback.days.ago)
                   .order(Arel.sql("centroid_embedding <=> #{Trend.connection.quote(centroid_literal)}"))
                   .first
      return nil unless trend

      dist = cosine_distance(trend.centroid_embedding.to_a, centroid)
      dist <= max_distance ? trend : nil
    end

    def generate_trend_metadata(articles)
      articles_text = articles.map.with_index do |a, idx|
        "#{idx + 1}. Title: #{a.title}\nTags: #{a.cached_tag_list}\nSummary: #{a.body_markdown.truncate(400)}"
      end.join("\n\n")

      prompt = <<~PROMPT
        You are analyzing a cluster of highly related technical articles published recently on a developer community platform.
        Your goal is to identify the emergent, specific trend or topic that groups these articles together, and produce structured information about it.

        Articles in this cluster:
        #{articles_text}

        Instructions:
        1. Identify the specific trend. Do NOT just use generic tags like "Ruby" or "CSS". Capture the specific, nuanced theme (e.g. "Ruby 3.4 Parser Migration" or "CSS Nesting vs Tailwind").
        2. Write a 2-3 sentence description summarizing the trend, why it is discussed, and its impact or interest to developers.
        3. Identify 2-3 key questions or sub-themes developers are exploring within this trend.
        4. Respond ONLY with a valid JSON object matching this schema:
        {
          "name": "Short, catchy Trend Title (max 50 chars)",
          "description": "2-3 sentence trend summary",
          "key_questions": ["Question 1", "Question 2", "Question 3"]
        }
      PROMPT

      begin
        response = @ai_client.call(prompt, response_mime_type: "application/json")
        return nil if response.blank?

        JSON.parse(response.strip)
      rescue StandardError => e
        Rails.logger.error("Trend Detector metadata generation failed: #{e.message}")
        nil
      end
    end

    def recalculate_trend_score(trend, days_lookback:)
      # Score is sum of (article.score * decay) for all articles associated in the lookback window
      recent_memberships = trend.trend_memberships
                                .joins(:article)
                                .where("articles.published_at >= ?", days_lookback.days.ago)
                                .includes(:article)

      total_score = 0.0
      recent_memberships.each do |m|
        days_old = (Time.current - m.article.published_at) / 1.day
        decay = 1.0 / (1.0 + (days_old / 3.0)) # 3 days half-life decay
        total_score += m.article.score * decay
      end

      trend.update_column(:score, total_score)
    end
  end
end
