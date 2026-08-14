module Concepts
  class EvaluateThresholdsWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

    def perform(concept_id = nil)
      if concept_id.present?
        concept = Concept.find_by(id: concept_id)
        return unless concept

        Concepts::ThresholdEvaluator.new(concept).call
      else
        Concept.find_each do |concept|
          Concepts::ThresholdEvaluator.new(concept).call
        end
      end
    end
  end
end
