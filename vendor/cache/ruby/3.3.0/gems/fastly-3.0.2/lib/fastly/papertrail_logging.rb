class Fastly
  # A Papertrail endpoint to stream logs to
  class PapertrailLogging < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :address, :port, :hostname, :format, :format_version, :response_condition, :timestamp_format

    ##
    # :attr: service_id
    #
    # The id of the service this belongs to.

    ##
    # :attr: version
    #
    # The number of the version this belongs to.

    ##
    # :attr: name
    #
    # The name for this s3 rule

    ##
    # :attr: address
    #
    # Hostname of the papertrail server - located at the top of your Papertrail
    # Setup e.g. https://papertrailapp.com/account/t destinations

    ##
    # :attr: port
    #
    # Port of the Papertrail server from Papertrail account

    ##
    # :attr: hostname
    #
    # Source name of the Fastly logs in Papertrail

    ##
    # :attr: format
    #
    # Apache style log formatting

    ##
    # :attr: format_version
    #
    # The version of the custom logging format used for the configured endpoint.
    # Can be either 1 (the default, version 1 log format) or 2 (the version 2
    # log format).

    ##
    # :attr: response_condition
    #
    # When to execute the logging. If empty, always execute.

    ##
    # :attr: timestamp_format
    #
    # strftime specified timestamp formatting (default "%Y-%m-%dT%H:%M:%S.000").

    def self.path
      'logging/papertrail'
    end
  end
end
