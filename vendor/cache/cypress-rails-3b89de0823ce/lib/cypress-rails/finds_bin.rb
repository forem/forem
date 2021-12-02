require "pathname"

module CypressRails
  class FindsBin
    LOCAL_PATH = "node_modules/.bin/cypress"
    LOCAL_KNAPSACK_PATH = "node_modules/.bin/knapsack-pro-cypress"

    def call(dir = Dir.pwd, knapsack = false)
      local_path = if knapsack
                     Pathname.new(dir).join(LOCAL_KNAPSACK_PATH)
                   else
                     Pathname.new(dir).join(LOCAL_PATH)
                   end

      if File.exist?(local_path)
        local_path
      else
        "cypress"
      end
    end
  end
end
