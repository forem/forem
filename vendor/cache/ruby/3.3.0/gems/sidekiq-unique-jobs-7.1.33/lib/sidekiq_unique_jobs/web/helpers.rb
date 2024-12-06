# frozen_string_literal: true

module SidekiqUniqueJobs
  module Web
    #
    # Provides view helpers for the Sidekiq::Web extension
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module Helpers
      #
      # @return [String] the path to gem specific views
      VIEW_PATH    = File.expand_path("../web/views", __dir__).freeze
      #
      # @return [Array<String>] safe params
      SAFE_CPARAMS = %w[
        filter count cursor prev_cursor poll direction
      ].freeze

      extend self

      #
      # Opens a template file contained within this gem
      #
      # @param [Symbol] name the name of the template
      #
      # @return [String] the file contents of the template
      #
      def unique_template(name)
        File.read(unique_filename(name))
      end

      #
      # Construct template file name
      #
      # @param [Symbol] name the name of the template
      #
      # @return [String] the full name of the file
      #
      def unique_filename(name)
        File.join(VIEW_PATH, "#{name}.erb")
      end

      #
      # The collection of digests
      #
      #
      # @return [SidekiqUniqueJobs::Digests] the sorted set with digests
      #
      def digests
        @digests ||= SidekiqUniqueJobs::Digests.new
      end

      #
      # The collection of digests
      #
      #
      # @return [SidekiqUniqueJobs::ExpiringDigests] the sorted set with expiring digests
      #
      def expiring_digests
        @expiring_digests ||= SidekiqUniqueJobs::ExpiringDigests.new
      end

      #
      # The collection of changelog entries
      #
      #
      # @return [SidekiqUniqueJobs::Digests] the sorted set with digests
      #
      def changelog
        @changelog ||= SidekiqUniqueJobs::Changelog.new
      end

      #
      # Creates url safe parameters
      #
      # @param [Hash] options the key/value to parameterize
      #
      # @return [String] a url safe parameter string
      #
      def cparams(options)
        stringified_options = options.transform_keys(&:to_s)
        params.merge(stringified_options).map do |key, value|
          next unless SAFE_CPARAMS.include?(key)

          "#{key}=#{CGI.escape(value.to_s)}"
        end.compact.join("&")
      end

      #
      # Used to avoid incompatibility with older sidekiq versions
      #
      #
      # @param [Array] args the unique arguments to display
      # @param [Integer] truncate_after_chars
      #
      # @return [String] a string containing all non-truncated arguments
      #
      def display_lock_args(args, truncate_after_chars = 2000)
        return "Invalid job payload, args is nil" if args.nil?
        return "Invalid job payload, args must be an Array, not #{args.class.name}" unless args.is_a?(Array)

        begin
          args.map do |arg|
            h(truncate(to_display(arg), truncate_after_chars))
          end.join(", ")
        rescue StandardError
          "Illegal job arguments: #{h args.inspect}"
        end
      end

      #
      # Redirect to with falback
      #
      # @param [String] subpath the path to redirect to
      #
      # @return a redirect to the new subpath
      #
      def redirect_to(subpath)
        if respond_to?(:to)
          # Sinatra-based web UI
          redirect to(subpath)
        else
          # Non-Sinatra based web UI (Sidekiq 4.2+)
          redirect "#{root_path}#{subpath}"
        end
      end

      #
      # Gets a relative time as html
      #
      # @param [Time] time an instance of Time
      #
      # @return [String] a html safe string with relative time information
      #
      def relative_time(time)
        stamp = time.getutc.iso8601
        %(<time class="ltr" dir="ltr" title="#{stamp}" datetime="#{stamp}">#{time}</time>)
      end

      #
      # Gets a relative time as html without crashing
      #
      # @param [Float, Integer, String, Time] time a representation of a timestamp
      #
      # @return [String] a html safe string with relative time information
      #
      def safe_relative_time(time)
        time = parse_time(time)

        relative_time(time)
      end

      #
      # Constructs a time from a number of different types
      #
      # @param [Float, Integer, String, Time] time a representation of a timestamp
      #
      # @return [Time]
      #
      def parse_time(time)
        case time
        when Time
          time
        when Integer, Float
          Time.at(time)
        else
          Time.parse(time.to_s)
        end
      end
    end
  end
end
