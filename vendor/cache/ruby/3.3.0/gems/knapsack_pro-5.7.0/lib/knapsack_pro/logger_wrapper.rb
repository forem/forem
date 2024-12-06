# frozen_string_literal: true

module KnapsackPro
  class LoggerWrapper
    def initialize(logger)
      @logger = logger
    end

    private

    attr_reader :logger

    LOG_LEVEL_METHODS = KnapsackPro::Config::Env::LOG_LEVELS.keys.map(&:to_sym)

    def method_missing(method, *args, &block)
      if LOG_LEVEL_METHODS.include?(method)
        args[0] = "[knapsack_pro] #{args[0]}"
      end
      logger.send(method, *args, &block)
    end
  end
end
