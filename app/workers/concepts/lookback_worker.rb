module Concepts
  class LookbackWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    def perform(concept_id, days)
      concept = Concept.find_by(id: concept_id)
      return unless concept

      days = days.to_i
      return if days <= 0

      prev_days = concept.max_lookback_days
      return if days <= prev_days

      start_time = days.days.ago

      overlap_days = 2
      if prev_days > 0 && prev_days > overlap_days
        end_time = (prev_days - overlap_days).days.ago
      else
        end_time = nil
      end

      vector_literal = "[#{concept.anchor_embedding.to_a.join(',')}]"
      quoted_vector = Concept.connection.quote(vector_literal)

      # 1. Query matching published articles
      articles_query = Article.published
        .select("articles.id, (semantic_embedding <=> #{quoted_vector}) AS computed_distance")
        .where.not(semantic_embedding: nil)
        .where("semantic_embedding <=> #{quoted_vector} <= ?", 0.14)
        .where("published_at >= ?", start_time)

      if end_time
        articles_query = articles_query.where("published_at <= ?", end_time)
      end

      matching_articles = articles_query.to_a

      memberships = matching_articles.map do |art|
        {
          concept_id: concept.id,
          record_type: "Article",
          record_id: art.id,
          distance: art.computed_distance.to_f,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # 2. Query matching comments
      comments_query = Comment
        .select("comments.id, (semantic_embedding <=> #{quoted_vector}) AS computed_distance")
        .where.not(semantic_embedding: nil)
        .where("semantic_embedding <=> #{quoted_vector} <= ?", 0.14)
        .where("created_at >= ?", start_time)

      if end_time
        comments_query = comments_query.where("created_at <= ?", end_time)
      end

      matching_comments = comments_query.to_a

      matching_comments.each do |com|
        memberships << {
          concept_id: concept.id,
          record_type: "Comment",
          record_id: com.id,
          distance: com.computed_distance.to_f,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # 3. Bulk upsert memberships
      if memberships.any?
        ConceptMembership.upsert_all(memberships, unique_by: %i[concept_id record_type record_id])
      end

      # 4. Update max_lookback_days
      concept.reload.update!(max_lookback_days: [concept.max_lookback_days, days].max)
    end
  end
end
