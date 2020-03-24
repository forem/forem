module Slack
  module Messengers
    class Note
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        *New note from %<name>s:*
        *Report status: %<status>s*
        Report page: #{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}/internal/reports/%<report_id>s
        --------
        Message: %<message>s
      TEXT

      def initialize(author_name:, status:, type:, report_id:, message:)
        @author_name = author_name
        @status = status
        @type = type
        @report_id = report_id
        @message = message
      end

      def self.call(*args)
        new(*args).call
      end

      def call
        final_message = format(
          MESSAGE_TEMPLATE,
          name: author_name,
          status: status,
          report_id: report_id,
          message: message,
        )

        SlackBotPingWorker.perform_async(
          message: final_message,
          channel: type,
          username: "new_note_bot",
          icon_emoji: ":memo:",
        )
      end

      private

      attr_reader :author_name, :status, :type, :report_id, :message
    end
  end
end
