module Concepts
  # Evaluates articles recently attributed to a concept via AI and adjusts the concept's similarity_threshold.
  # - If all evaluated recent articles are appropriate, slightly INCREASES the threshold to catch more content.
  # - If any inappropriate articles are detected, DECREASES the threshold to be more strict and removes the invalid
  #   memberships.
  class ThresholdEvaluator
    DEFAULT_STEP = 0.01
    MIN_THRESHOLD = 0.10
    MAX_THRESHOLD = 0.60

    def initialize(concept, lookback_period: 3.hours, step: DEFAULT_STEP)
      @concept = concept
      @lookback_period = lookback_period
      @step = step
    end

    def call
      start_time = @lookback_period.ago
      memberships = @concept.concept_memberships
        .where(record_type: "Article")
        .where("created_at >= ?", start_time)
        .includes(:record)

      return if memberships.empty?

      appropriate_count = 0
      inappropriate_count = 0
      inappropriate_memberships = []

      memberships.each do |membership|
        article = membership.record
        next unless article.is_a?(Article) && article.published?

        evaluator = Ai::ConceptArticleEvaluator.new(@concept, article)
        is_appropriate = evaluator.appropriate?

        case is_appropriate
        when true
          appropriate_count += 1
        when false
          inappropriate_count += 1
          inappropriate_memberships << membership
        end
      end

      total_evaluated = appropriate_count + inappropriate_count
      return if total_evaluated.zero?

      current_threshold = @concept.similarity_threshold || Concepts::Classifier::DEFAULT_THRESHOLD

      new_threshold = if inappropriate_count.zero?
                        # All evaluated articles fit -> slightly loosen threshold to catch more
                        current_threshold + @step
                      else
                        # Found articles that don't fit -> tighten threshold to be more strict
                        current_threshold - @step
                      end

      clamped_threshold = new_threshold.round(4).clamp(MIN_THRESHOLD, MAX_THRESHOLD)

      Concept.transaction do
        @concept.update!(similarity_threshold: clamped_threshold)

        # Remove false positive memberships caught during evaluation
        inappropriate_memberships.each(&:destroy)
      end

      clamped_threshold
    end
  end
end
