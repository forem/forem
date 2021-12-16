module CypressRails
  class FindsBin
    def call(_dir = Dir.pwd)
      if ENV["KNAPSACK_PRO_CI_NODE_TOTAL"].present? && ENV["KNAPSACK_PRO_CI_NODE_INDEX"].present?
        "node_modules/.bin/knapsack-pro-cypress"
      else
        "node_modules/.bin/cypress"
      end
    end
  end
end
