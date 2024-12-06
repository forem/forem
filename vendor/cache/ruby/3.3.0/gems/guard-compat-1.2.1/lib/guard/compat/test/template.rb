module Guard
  module Compat
    module Test
      class Template
        class Session
          class MultipleGuardNotImplemented < NotImplementedError
            def message
              'multiple guards not supported!'
            end
          end

          class GlobalWatchesNotImplemented < NotImplementedError
            def message
              'global watches not supported!'
            end
          end

          def initialize(path, content)
            @watches = {}
            @current = nil
            instance_eval(content, path, 1)
          end

          def match(file)
            _watches.map do |expr, block|
              next unless (match = file.match(expr))
              block.nil? ? [file] : block.call([file] + match.captures)
            end.flatten.compact.uniq
          end

          def guard(name, _options = {})
            @current = name
            @watches[@current] = []
            yield
            @current = nil
          end

          def watch(expr, &block)
            @watches[@current] << [expr, block]
          end

          private

          def _watches
            keys = @watches.keys
            fail ArgumentError, 'no watches!' if keys.empty?
            fail MultipleGuardNotImplemented if keys.size > 1

            key = keys.first
            fail GlobalWatchesNotImplemented if key.nil?
            @watches[key]
          end
        end

        def initialize(plugin_class)
          name = plugin_class.to_s.sub('Guard::', '').downcase
          path = format('lib/guard/%s/templates/Guardfile', name)
          content = File.read(path)
          @session = Session.new(path, content)
        end

        def changed(file)
          @session.match(file)
        end
      end
    end
  end
end
