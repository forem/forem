module Slack
  module Messengers
    class Note
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        *New note from %<name>s:*
        *Report status: %<status>s*
        Report page: %<report_url>s
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

      def self.call(...)
        new(...).call
      end

      def call
        report_url = URL.url(
          Rails.application.routes.url_helpers.admin_report_path(report_id),
        )

        final_message = format(
          MESSAGE_TEMPLATE,
          name: author_name,
          status: status,
          report_url: report_url,
          message: message,
        )

        Slack::Messengers::Worker.perform_async(
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
