require "guard/config"
fail "Deprecations disabled (strict mode)" if Guard::Config.new.strict?

module Guard
  module Deprecated
    module Watcher
      def self.add_deprecated(klass)
        klass.send(:extend, ClassMethods)
      end

      module ClassMethods
        MATCH_GUARDFILE = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.8.3 this method is deprecated.
        EOS

        def match_guardfile?(files)
          require "guard/guardfile/evaluator"
          UI.deprecation(MATCH_GUARDFILE)
          options = ::Guard.state.session.evaluator_options
          evaluator = ::Guard::Guardfile::Evaluator.new(options)
          path = evaluator.guardfile_path
          files.any? { |file| File.expand_path(file) == path }
        end
      end
    end
  end
end
