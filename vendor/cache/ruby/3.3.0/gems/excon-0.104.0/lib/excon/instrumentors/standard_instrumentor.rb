# frozen_string_literal: true
module Excon
  class StandardInstrumentor
    def self.instrument(name, params = {})
      params = params.dup

      # reduce duplication/noise of output
      params.delete(:connection)
      params.delete(:stack)

      params = Utils.redact(params)

      $stderr.puts(name)
      Excon::PrettyPrinter.pp($stderr, params)

      if block_given?
        yield
      end
    end
  end
end
