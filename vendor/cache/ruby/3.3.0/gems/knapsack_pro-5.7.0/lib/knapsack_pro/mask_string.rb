# frozen_string_literal: true

module KnapsackPro
  class MaskString
    def self.call(string)
      string.gsub(/(?<=\w{2})[a-zA-Z]/, "*")
    end
  end
end
