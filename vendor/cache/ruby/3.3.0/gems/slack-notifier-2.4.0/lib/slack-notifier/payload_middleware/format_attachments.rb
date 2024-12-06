# frozen_string_literal: true

module Slack
  class Notifier
    class PayloadMiddleware
      class FormatAttachments < Base
        middleware_name :format_attachments

        options formats: %i[html markdown]

        def call payload={}
          payload = payload.dup
          attachments = payload.delete(:attachments)
          attachments ||= payload.delete("attachments")

          attachments = wrap_array(attachments).map do |attachment|
            ["text", :text].each do |key|
              if attachment.key?(key)
                attachment[key] = Util::LinkFormatter.format(attachment[key], options)
              end
            end

            attachment
          end

          payload[:attachments] = attachments if attachments && !attachments.empty?
          payload
        end

        private

          def wrap_array object
            if object.nil?
              []
            elsif object.respond_to?(:to_ary)
              object.to_ary || [object]
            else
              [object]
            end
          end
      end
    end
  end
end
