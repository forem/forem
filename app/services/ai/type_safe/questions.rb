module Ai
  module TypeSafe
    ##
    # Builders for System One question payloads. See https://docs.typesafe.ai/primitives.
    #
    # Guidance baked into how Forem uses these:
    # - One narrow judgment per question; compose answers in Ruby with explicit thresholds.
    # - Point at parts of the state with backticked paths such as `article.title`.
    # - Instructions and criteria may be strings, hashes or arrays; use hashes to separate the
    #   question from supporting data or to spell out what an option is and is not for.
    # - Phrase Nouls so that a high value means yes.
    module Questions
      MAX_CHOICE_OPTIONS = 255
      MAX_SCORE_LEVELS = 10

      module_function

      # A yes/no judgment. Returns the probability of yes. `yes`/`no` describe what each
      # answer covers (sent as the API's `true`/`false` criteria).
      def noul(instructions, yes: nil, no: nil) # rubocop:disable Naming/MethodParameterName
        question = { type: "noul", instructions: instructions }
        criteria = { "true" => yes, "false" => no }.compact
        question[:criteria] = criteria if criteria.any?
        question
      end

      # Picks one option from a set. criteria is option => description (or nil).
      def choice(instructions, criteria)
        raise ArgumentError, "A Choice needs at least two options" if criteria.size < 2
        if criteria.size > MAX_CHOICE_OPTIONS
          raise ArgumentError, "A Choice accepts at most #{MAX_CHOICE_OPTIONS} options"
        end

        { type: "choice", instructions: instructions, criteria: criteria.transform_keys(&:to_s) }
      end

      # Places the state along ordered levels. Each level should describe a concrete
      # situation that stands on its own; the model never sees level numbers.
      def score(instructions, levels)
        unless levels.size.between?(2, MAX_SCORE_LEVELS)
          raise ArgumentError, "A Score needs between 2 and #{MAX_SCORE_LEVELS} levels"
        end

        { type: "score", instructions: instructions, criteria: levels }
      end
    end
  end
end
