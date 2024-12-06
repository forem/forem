# Note: currently, this file only exists to allow Bundler to require this file
# without crashing (e.g. when Guard hasn't been included)

unless Object.const_defined?('Guard')
  module Guard
  end
end

unless Guard.const_defined?('Plugin')
  # Provided empty definition so requiring the plugin without Guard won't crash
  # (e.g. when added to a Gemfile without `require: false`)
  module Guard
    class Plugin
      def initialize(_options = {})
        msg = 'either Guard has not been required or you did not' \
          ' include guard/compat/test/helper'
        fail NotImplementedError, msg
      end
    end
  end
end

module Guard
  module Compat
    # TODO: this is just a temporary workaround to allow plugins
    # to use watcher patterns in run_all
    def self.matching_files(plugin, files)
      unless Guard.const_defined?('Watcher')
        msg = 'either Guard has not been required or you did not' \
          ' stub this method in your plugin tests'
        fail NotImplementedError, msg
      end

      # TODO: uniq not tested
      # TODO: resolve symlinks and then uniq?
      Guard::Watcher.match_files(plugin, files).uniq
    end

    def self.watched_directories
      unless Guard.const_defined?('CLI')
        fail NotImplementedError, 'either Guard has not been required or'\
          ' you did not stub this method in your plugin tests'
      end

      if Guard.respond_to?(:state)
        # TODO: the new version is temporary
        Guard.state.session.watchdirs.map { |d| Pathname(d) }
      else
        dirs = Array(Guard.options(:watchdir))
        dirs.empty? ? [Pathname.pwd] : dirs.map { |d| Pathname(d) }
      end
    end

    module UI
      def self.color(text, *colors)
        if Guard.const_defined?(:UI)
          Guard::UI.send(:color, text, *colors)
        else
          text
        end
      end

      def self.color_enabled?
        if Guard.const_defined?(:UI)
          Guard::UI.send(:color_enabled?)
        else
          false
        end
      end

      def self.info(message, options = {})
        if Guard.const_defined?(:UI)
          Guard::UI.info(message, options)
        else
          $stdout.puts(message)
        end
      end

      def self.warning(message, options = {})
        if Guard.const_defined?(:UI)
          Guard::UI.warning(message, options)
        else
          $stdout.puts(message)
        end
      end

      def self.error(message, options = {})
        if Guard.const_defined?(:UI)
          Guard::UI.error(message, options)
        else
          $stderr.puts(message)
        end
      end

      def self.debug(message, options = {})
        if Guard.const_defined?(:UI)
          Guard::UI.debug(message, options)
        else
          $stdout.puts(message)
        end
      end

      def self.deprecation(message, options = {})
        if Guard.const_defined?(:UI)
          Guard::UI.deprecation(message, options)
        else
          $stdout.puts(message)
        end
      end

      def self.notify(msg, options = {})
        return $stdout.puts(msg) unless Guard.const_defined?(:UI)
        return Notifier.notify(msg, options) if Notifier.respond_to?(:notify)

        # test helper was included
        note = 'NOTE: Notification is disabled when testing Guard plugins'\
          ' (it makes no sense)'

        $stderr.puts(note)
        $stdout.puts(msg)
      end
    end
  end
end
