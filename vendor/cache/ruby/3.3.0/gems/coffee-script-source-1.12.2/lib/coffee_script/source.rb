module CoffeeScript
  module Source
    def self.bundled_path
      File.expand_path("../coffee-script.js", __FILE__)
    end
  end
end
