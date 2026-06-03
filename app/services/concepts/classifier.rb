module Concepts
  class Classifier
    DEFAULT_THRESHOLD = 0.14

    def initialize(record)
      @record = record
    end

    def call(threshold: DEFAULT_THRESHOLD)
      record_vector = @record.semantic_embedding
      return if record_vector.blank?

      vector_array = record_vector.to_a
      return unless vector_array.length == 768

      vector_literal = "[#{vector_array.join(',')}]"
      quoted_vector = Concept.connection.quote(vector_literal)

      # Query concepts that match within the threshold
      matching_concepts = Concept
        .select("concepts.*, (anchor_embedding <=> #{quoted_vector}) AS computed_distance")
        .where("anchor_embedding <=> #{quoted_vector} <= ?", threshold)
        .to_a

      active_concept_ids = matching_concepts.map(&:id)

      ConceptMembership.transaction do
        # 1. Remove memberships that no longer qualify
        @record.concept_memberships.where.not(concept_id: active_concept_ids).destroy_all

        # 2. Add or update current matching memberships
        matching_concepts.each do |concept|
          membership = @record.concept_memberships.find_or_initialize_by(concept_id: concept.id)
          membership.distance = concept.computed_distance.to_f
          membership.save!
        end
      end
    end
  end
end
