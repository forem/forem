require "pathname"

module CypressRails
  class FindsBin
    LOCAL_PATH = "node_modules/.bin/cypress"

    def call(dir = Dir.pwd)
      local_path = Pathname.new(dir).join(LOCAL_PATH)
      if File.exist?(local_path)
        local_path
      else
        "cypress"
      end
    end
  end
end
