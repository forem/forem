require "zip"

module Exporter
  class Service
    attr_reader :user

    EXPORTERS = [
      Exporter::Articles,
      Exporter::Comments,
    ].freeze

    def initialize(user)
      @user = user
    end

    def export(email, config: {})
      exports = {}

      # export content with filenames
      EXPORTERS.each do |exporter|
        files = exporter.new(user).export(**config.fetch(exporter.name.demodulize.downcase.to_sym, {}))
        files.each do |name, content|
          exports[name] = content
        end
      end

      zipped_exports = zip_exports(exports)

      send_exports_by_email(zipped_exports, email)

      update_user_export_fields

      zipped_exports.rewind
      zipped_exports
    end

    private

    def zip_exports(exports)
      buffer = StringIO.new
      Zip::OutputStream.write_buffer(buffer) do |stream|
        exports.each do |name, content|
          stream.put_next_entry(
            name,
            nil, # comment
            nil, # extra
            Zip::Entry::DEFLATED,
            Zlib::BEST_COMPRESSION,
          )
          stream.write content
        end
      end
      buffer
    end

    def send_exports_by_email(zipped_exports, email)
      zipped_exports.rewind
      NotifyMailer.with(email: email, attachment: zipped_exports.read).export_email.deliver_now
    end

    def update_user_export_fields
      user.update!(export_requested: false, exported_at: Time.current)
    end
  end
end
