require "pathname"

module CypressRails
  class FindsBin
    LOCAL_PATH = "node_modules/.bin/cypress"

    def call(cypress_dir = Dir.pwd)
      local_path = Pathname.new(cypress_dir).join(LOCAL_PATH)
      if File.exist?(local_path)
        local_path
      else
        "cypress"
      end
    end
  end
end
