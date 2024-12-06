# frozen_string_literal: true

module TestProf
  module MemoryProf
    class Printer
      module NumberToHuman
        BASE = 1024
        UNITS = %w[B KB MB GB TB PB EB ZB]

        class << self
          def convert(number)
            exponent = exponent(number)
            human_size = number.to_f / (BASE**exponent)

            "#{round(human_size)}#{UNITS[exponent]}"
          end

          private

          def exponent(number)
            return 0 unless number.positive?

            max = UNITS.size - 1

            exponent = (Math.log(number) / Math.log(BASE)).to_i
            (exponent > max) ? max : exponent
          end

          def round(number)
            if integer?(number)
              number.round
            else
              number.round(2)
            end
          end

          def integer?(number)
            number.round == number
          end
        end
      end
    end
  end
end
