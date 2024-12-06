# frozen_string_literal: true

module Puma
  class IOBuffer < String
    def append(*args)
      args.each { |a| concat(a) }
    end

    alias reset clear
  end
end
