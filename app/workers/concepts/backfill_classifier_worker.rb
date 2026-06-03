module Concepts
  class BackfillClassifierWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    def perform(concept_id)
      concept = Concept.find_by(id: concept_id)
      return unless concept

      vector_literal = "[#{concept.anchor_embedding.to_a.join(',')}]"
      quoted_vector = Concept.connection.quote(vector_literal)

      # 1. Clean up existing memberships for this concept
      concept.concept_memberships.destroy_all

      # 2. Query all matching published articles
      matching_articles = Article.published
        .select("articles.id, (semantic_embedding <=> #{quoted_vector}) AS computed_distance")
        .where.not(semantic_embedding: nil)
        .where("semantic_embedding <=> #{quoted_vector} <= ?", 0.14)
        .to_a

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

      # 3. Query all matching comments
      matching_comments = Comment
        .select("comments.id, (semantic_embedding <=> #{quoted_vector}) AS computed_distance")
        .where.not(semantic_embedding: nil)
        .where("semantic_embedding <=> #{quoted_vector} <= ?", 0.14)
        .to_a

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

      # 4. Bulk insert memberships
      return unless memberships.any?

      ConceptMembership.insert_all!(memberships)
    end
  end
end
