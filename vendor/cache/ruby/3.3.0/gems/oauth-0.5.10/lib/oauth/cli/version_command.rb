class OAuth::CLI
  class VersionCommand < BaseCommand
    def run
      puts "OAuth Gem #{OAuth::VERSION}"
    end
  end
end
