require_relative "launches_cypress"
require_relative "config"

module CypressRails
  class RunKnapsack
    def initialize
      @launches_cypress = LaunchesCypress.new
    end

    def call(config = Config.new)
      config.knapsack = true
      @launches_cypress.call(nil, config)
    end
  end
end
