module Honeybadger
  module Util
    class Revision
      class << self
        def detect(root = Dir.pwd)
          revision = from_heroku ||
            from_capistrano(root) ||
            from_git

          revision = revision.to_s.strip
          return unless revision =~ /\S/

          revision
        end

        private

        # Requires (currently) alpha platform feature `heroku labs:enable
        # runtime-dyno-metadata`
        #
        # See https://devcenter.heroku.com/articles/dyno-metadata
        def from_heroku
          ENV['HEROKU_SLUG_COMMIT']
        end

        def from_capistrano(root)
          file = File.join(root, 'REVISION')
          return nil unless File.file?(file)
          File.read(file) rescue nil
        end

        def from_git
          return nil unless File.directory?('.git')
          `git rev-parse HEAD 2> #{File::NULL}` rescue nil
        end
      end
    end
  end
end
