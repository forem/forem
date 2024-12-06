# frozen_string_literal: true

module Rouge
  class Guesser
    class Ambiguous < StandardError
      attr_reader :alternatives
      def initialize(alternatives); @alternatives = alternatives; end

      def message
        "Ambiguous guess: can't decide between #{alternatives.map(&:tag).inspect}"
      end
    end

    def self.guess(guessers, lexers)
      original_size = lexers.size

      guessers.each do |g|
        new_lexers = case g
        when Guesser then g.filter(lexers)
        when proc { |x| x.respond_to? :call } then g.call(lexers)
        else raise "bad guesser: #{g}"
        end

        lexers = new_lexers && new_lexers.any? ? new_lexers : lexers
      end

      # if we haven't filtered the input at *all*,
      # then we have no idea what language it is,
      # so we bail and return [].
      lexers.size < original_size ? lexers : []
    end

    def collect_best(lexers, opts={}, &scorer)
      best = []
      best_score = opts[:threshold]

      lexers.each do |lexer|
        score = scorer.call(lexer)

        next if score.nil?

        if best_score.nil? || score > best_score
          best_score = score
          best = [lexer]
        elsif score == best_score
          best << lexer
        end
      end

      best
    end

    def filter(lexers)
      raise 'abstract'
    end
  end
end
