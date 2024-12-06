require "nenv"

module Guard
  config_class = Nenv::Builder.build do
    create_method(:strict?)
    create_method(:gem_silence_deprecations?)
  end

  class Config < config_class
    def initialize
      super "guard"
    end

    def silence_deprecations?
      gem_silence_deprecations?
    end
  end
end
