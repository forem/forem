module Ai
  module TypeSafe
    ##
    # Typed view of a System One response.
    #
    # - Noul answers are a single probability that the answer is yes (0..1). They carry no
    #   separate confidence; a value near 0.5 means "uncertain", not "medium".
    # - Choice answers carry the chosen option, the full distribution and a confidence.
    # - Score answers carry a probability-weighted position across the levels (0..levels-1),
    #   the distribution and a confidence.
    class Result
      Choice = Struct.new(:choice, :probabilities, :confidence, keyword_init: true)
      Score = Struct.new(:score, :probabilities, :confidence, :levels, keyword_init: true) do
        # Position normalized to 0..1. Use this to rank or threshold, never to recover an
        # exact magnitude between two levels.
        def normalized
          return 0.0 if levels.to_i < 2

          (score.to_f / (levels - 1)).clamp(0.0, 1.0)
        end
      end

      class MissingAnswerError < StandardError; end

      attr_reader :model, :raw

      def initialize(parsed_response)
        @raw = parsed_response
        @model = parsed_response["model"]
        @answers = parsed_response["answers"]
      end

      def key?(id)
        @answers.key?(id.to_s)
      end

      def noul(id)
        answer(id, "noul")["noul"].to_f
      end

      def choice(id)
        data = answer(id, "choice")
        Choice.new(choice: data["choice"], probabilities: data["probabilities"] || {},
                   confidence: data["confidence"].to_f)
      end

      def score(id)
        data = answer(id, "score")
        Score.new(score: data["score"].to_f, probabilities: data["probabilities"] || {},
                  confidence: data["confidence"].to_f, levels: (data["legend"] || data["probabilities"] || {}).size)
      end

      # Nouls for every question id with the given prefix, keyed by the remainder of the id.
      # Handy for per-candidate batteries such as "tag::javascript".
      def nouls_with_prefix(prefix)
        @answers.each_with_object({}) do |(id, data), memo|
          next unless id.start_with?(prefix) && data["type"] == "noul"

          memo[id.delete_prefix(prefix)] = data["noul"].to_f
        end
      end

      private

      def answer(id, type)
        data = @answers[id.to_s]
        raise MissingAnswerError, "No #{type} answer for question '#{id}'" unless data
        unless data["type"] == type
          raise MissingAnswerError, "Question '#{id}' returned #{data['type']}, expected #{type}"
        end

        data
      end
    end
  end
end
