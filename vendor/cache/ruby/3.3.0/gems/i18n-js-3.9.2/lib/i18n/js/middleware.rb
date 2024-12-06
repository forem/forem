require "fileutils"

module I18n
  module JS
    class Middleware
      def initialize(app)
        @app = app
        clear_cache
      end

      def call(env)
        @cache = nil
        verify_locale_files!
        @app.call(env)
      end

      private
      def cache_path
        @cache_path ||= cache_dir.join("i18n-js.yml")
      end

      def cache_dir
        @cache_dir ||= Rails.root.join("tmp/cache")
      end

      def cache
        @cache ||= begin
          if cache_path.exist?
            YAML.load_file(cache_path) || {}
          else
            {}
          end
        end
      end

      def clear_cache
        # `File.delete` will raise error when "multiple worker"
        # Are running at the same time, like in a parallel test
        #
        # `FileUtils.rm_f` is tested manually
        #
        # See https://github.com/fnando/i18n-js/issues/436
        FileUtils.rm_f(cache_path) if File.exist?(cache_path)
      end

      def save_cache(new_cache)
        # path could be a symbolic link
        FileUtils.mkdir_p(cache_dir) unless File.exist?(cache_dir)
        File.open(cache_path, "w+") do |file|
          file << new_cache.to_yaml
        end
      end

      # Check if translations should be regenerated.
      # ONLY REGENERATE when these conditions are met:
      #
      # # Cache file doesn't exist
      # # Translations and cache size are different (files were removed/added)
      # # Translation file has been updated
      #
      def verify_locale_files!
        valid_cache = []
        new_cache = {}

        valid_cache.push cache_path.exist?
        valid_cache.push ::I18n.load_path.uniq.size == cache.size

        ::I18n.load_path.each do |path|
          changed_at = File.mtime(path).to_i
          valid_cache.push changed_at == cache[path]
          new_cache[path] = changed_at
        end

        return if valid_cache.all?

        save_cache(new_cache)

        ::I18n::JS.export
      end
    end
  end
end
