# Shared AI disclosure behavior and synonym normalization for models with an
# `ai_disclosure_level` enum (Article, Comment).
module AiDisclosable
  extend ActiveSupport::Concern

  LEVELS = {
    not_disclosed: 0,
    no_ai: 1,
    some_ai: 3,
    fully_autonomous: 5
  }.freeze

  # Maps common synonyms, numeric strings, and LLM/user-supplied variations
  # to canonical `ai_disclosure_level` enum keys.
  SIMILAR_TERMS = {
    # not_disclosed (0)
    "0" => :not_disclosed,
    "not_disclosed" => :not_disclosed,
    "undisclosed" => :not_disclosed,
    "not_specified" => :not_disclosed,
    "unspecified" => :not_disclosed,
    "unstated" => :not_disclosed,
    "unknown" => :not_disclosed,
    "false" => :not_disclosed,
    "n/a" => :not_disclosed,
    "na" => :not_disclosed,
    "null" => :not_disclosed,
    "nil" => :not_disclosed,
    "default" => :not_disclosed,

    # no_ai (1)
    "1" => :no_ai,
    "no_ai" => :no_ai,
    "no" => :no_ai,
    "none" => :no_ai,
    "human" => :no_ai,
    "human_only" => :no_ai,
    "human_written" => :no_ai,
    "human_authored" => :no_ai,
    "human_created" => :no_ai,
    "all_human" => :no_ai,
    "only_human" => :no_ai,
    "100%_human" => :no_ai,
    "100_human" => :no_ai,
    "pure_human" => :no_ai,
    "purely_human" => :no_ai,
    "hand_written" => :no_ai,
    "handwritten" => :no_ai,
    "hand_crafted" => :no_ai,
    "handcrafted" => :no_ai,
    "manual" => :no_ai,
    "organic" => :no_ai,
    "zero_ai" => :no_ai,
    "without_ai" => :no_ai,
    "non_ai" => :no_ai,
    "not_ai" => :no_ai,
    "no_ai_used" => :no_ai,

    # some_ai (3)
    "2" => :some_ai,
    "3" => :some_ai,
    "4" => :some_ai,
    "some_ai" => :some_ai,
    "some" => :some_ai,
    "assisted" => :some_ai,
    "ai_assisted" => :some_ai,
    "ai_assist" => :some_ai,
    "ai_assistance" => :some_ai,
    "with_ai" => :some_ai,
    "ai_enhanced" => :some_ai,
    "ai_edited" => :some_ai,
    "ai_polished" => :some_ai,
    "ai_supported" => :some_ai,
    "ai_helped" => :some_ai,
    "ai_augmented" => :some_ai,
    "ai_aided" => :some_ai,
    "ai_drafted" => :some_ai,
    "ai_translated" => :some_ai,
    "co_authored" => :some_ai,
    "ai_co_authored" => :some_ai,
    "co_piloted" => :some_ai,
    "copiloted" => :some_ai,
    "copilot" => :some_ai,
    "hybrid" => :some_ai,
    "partial" => :some_ai,
    "partial_ai" => :some_ai,
    "partially_ai" => :some_ai,
    "partially_ai_generated" => :some_ai,
    "mixed" => :some_ai,
    "collaborative" => :some_ai,
    "ai_collaborative" => :some_ai,
    "human_and_ai" => :some_ai,
    "light_ai" => :some_ai,
    "minimal_ai" => :some_ai,
    "minor_ai" => :some_ai,
    "moderate_ai" => :some_ai,
    "medium" => :some_ai,
    "low" => :some_ai,

    # fully_autonomous (5)
    "5" => :fully_autonomous,
    "fully_autonomous" => :fully_autonomous,
    "autonomous" => :fully_autonomous,
    "autonomous_ai" => :fully_autonomous,
    "full" => :fully_autonomous,
    "full_ai" => :fully_autonomous,
    "fully_ai" => :fully_autonomous,
    "all_ai" => :fully_autonomous,
    "100%_ai" => :fully_autonomous,
    "100_ai" => :fully_autonomous,
    "pure_ai" => :fully_autonomous,
    "purely_ai" => :fully_autonomous,
    "ai_only" => :fully_autonomous,
    "only_ai" => :fully_autonomous,
    "ai_generated" => :fully_autonomous,
    "fully_ai_generated" => :fully_autonomous,
    "generated" => :fully_autonomous,
    "generated_by_ai" => :fully_autonomous,
    "ai_written" => :fully_autonomous,
    "written_by_ai" => :fully_autonomous,
    "ai_authored" => :fully_autonomous,
    "authored_by_ai" => :fully_autonomous,
    "ai_created" => :fully_autonomous,
    "created_by_ai" => :fully_autonomous,
    "ai" => :fully_autonomous,
    "agent" => :fully_autonomous,
    "agentic" => :fully_autonomous,
    "agent_generated" => :fully_autonomous,
    "bot" => :fully_autonomous,
    "automated" => :fully_autonomous,
    "auto" => :fully_autonomous,
    "llm" => :fully_autonomous,
    "llm_generated" => :fully_autonomous,
    "machine_generated" => :fully_autonomous,
    "synthetic" => :fully_autonomous,
    "high" => :fully_autonomous,
    "true" => :fully_autonomous
  }.freeze

  included do
    enum :ai_disclosure_level, LEVELS

    def ai_disclosure_level=(value)
      if value.nil? || (value.is_a?(String) && value.strip.empty?)
        super(:not_disclosed)
      else
        normalized = self.class.normalize_ai_disclosure_level(value)
        super(normalized || value)
      end
    end
  end

  class_methods do
    # Normalizes an arbitrary input into a canonical `ai_disclosure_level` symbol,
    # or returns `nil` if the input does not match any known term.
    def normalize_ai_disclosure_level(raw_value)
      return if raw_value.nil?
      return :fully_autonomous if raw_value == true
      return :not_disclosed if raw_value == false

      if raw_value.is_a?(Integer)
        key = ai_disclosure_levels.key(raw_value)
        return key.to_sym if key

        return SIMILAR_TERMS[raw_value.to_s]
      end

      cleaned = raw_value.to_s.strip.downcase.gsub(/[\s\-]+/, "_").squeeze("_").gsub(/\A_|_\z/, "")
      return :not_disclosed if cleaned.empty?

      return SIMILAR_TERMS[cleaned] if SIMILAR_TERMS.key?(cleaned)
      return cleaned.to_sym if ai_disclosure_levels.key?(cleaned)

      nil
    end
  end

  def ai_disclosed?
    some_ai? || fully_autonomous?
  end
end
