module BetterErrors
  # @private
  module REPL
    PROVIDERS = [
        { impl:   "better_errors/repl/basic",
          const:  :Basic },
      ]

    def self.provider
      @provider ||= const_get detect[:const]
    end

    def self.provider=(prov)
      @provider = prov
    end

    def self.detect
      PROVIDERS.find { |prov|
        test_provider prov
      }
    end

    def self.test_provider(provider)
      # We must load this file instead of `require`ing it, since during our tests we want the file
      # to be reloaded. In practice, this will only be called once, so `require` is not necessary.
      load "#{provider[:impl]}.rb"
      true
    rescue LoadError
      false
    end
  end
end
