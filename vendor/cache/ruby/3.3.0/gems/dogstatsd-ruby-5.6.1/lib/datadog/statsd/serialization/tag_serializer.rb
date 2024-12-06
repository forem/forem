# frozen_string_literal: true

module Datadog
  class Statsd
    module Serialization
      class TagSerializer
        def initialize(global_tags = [], env = ENV)
          # Convert to hash
          global_tags = to_tags_hash(global_tags)

          # Merge with default tags
          global_tags = default_tags(env).merge(global_tags)

          # Convert to tag list and set
          @global_tags = to_tags_list(global_tags)
          if @global_tags.any?
            @global_tags_formatted = @global_tags.join(',')
          else
            @global_tags_formatted = nil
          end
        end

        def format(message_tags)
          if !message_tags || message_tags.empty?
            return @global_tags_formatted
          end

          tags = if @global_tags_formatted
                   [@global_tags_formatted, to_tags_list(message_tags)]
                 else
                   to_tags_list(message_tags)
                 end

          tags.join(',')
        end

        attr_reader :global_tags

        private

        def to_tags_hash(tags)
          case tags
          when Hash
            tags.dup
          when Array
            Hash[
              tags.map do |string|
                tokens = string.split(':')
                tokens << nil if tokens.length == 1
                tokens.length == 2 ? tokens : nil
              end.compact
            ]
          else
            {}
          end
        end

        def to_tags_list(tags)
          case tags
          when Hash
            tags.map do |name, value|
              if value
                escape_tag_content("#{name}:#{value}")
              else
                escape_tag_content(name)
              end
            end
          when Array
            tags.map { |tag| escape_tag_content(tag) }
          else
            []
          end
        end

        def escape_tag_content(tag)
          tag.to_s.delete('|,')
        end

        def dd_tags(env = ENV)
          return {} unless dd_tags = env['DD_TAGS']

          to_tags_hash(dd_tags.split(','))
        end

        def default_tags(env = ENV)
          dd_tags(env).tap do |tags|
            tags['dd.internal.entity_id'] = env['DD_ENTITY_ID'] if env.key?('DD_ENTITY_ID')
            tags['env'] = env['DD_ENV'] if env.key?('DD_ENV')
            tags['service'] = env['DD_SERVICE'] if env.key?('DD_SERVICE')
            tags['version'] = env['DD_VERSION'] if env.key?('DD_VERSION')
          end
        end
      end
    end
  end
end
