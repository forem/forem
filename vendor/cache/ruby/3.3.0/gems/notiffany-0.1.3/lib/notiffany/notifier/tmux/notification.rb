module Notiffany
  class Notifier
    class Tmux < Base
      # Wraps a notification with it's options
      class Notification
        def initialize(type, options)
          @type = type
          @options = options
          @color = options[type.to_sym] || options[:default]
          @separator = options[:line_separator]
          @message_color = _value_for(:message_color)
          @client = Client.new(options[:display_on_all_clients] ? :all : nil)
        end

        def display_title(title, message)
          title_format = _value_for(:title_format)

          teaser_message = message.split("\n").first
          display_title = format(title_format, title, teaser_message)

          client.title = display_title
        end

        def display_message(title, message)
          message = _message_for(title, message)

          client.display_time = options[:timeout] * 1000
          client.message_fg = message_color
          client.message_bg = color
          client.display_message(message)
        end

        def colorize(locations)
          locations.each do |location|
            client.set(location, color)
          end
        end

        private

        attr_reader :type
        attr_reader :options
        attr_reader :color
        attr_reader :message_color
        attr_reader :client
        attr_reader :separator

        def _value_for(field)
          format = "#{type}_#{field}".to_sym
          default = options["default_#{field}".to_sym]
          options.fetch(format, default)
        end

        def _message_for(title, message)
          message_format = _value_for(:message_format)
          formatted_message = message.split("\n").join(separator)
          format(message_format, title, formatted_message)
        end
      end
    end
  end
end
