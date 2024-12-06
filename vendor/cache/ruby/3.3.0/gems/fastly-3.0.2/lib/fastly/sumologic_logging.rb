class Fastly
  # An Google Cloud Storage endpoint to stream logs to
  class SumologicLogging < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :url, :period, :placement, :gzip_level, :format, :comment, :format_version, :message_type, :response_condition, :timestamp_format, :created_at, :updated_at, :deleted_at

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
    # The name for this gcs rule

    ##
    # :attr: url
    #
    # The collector endpoint URL defined by Sumologic

    ##
    # :attr: period
    #
    # How frequently the logs should be dumped (in seconds, default 3600)

    ##
    # :attr: placement
    #
    # Where in the generated VCL the logging call should be placed

    ##
    # :attr: gzip_level
    #
    # What level of gzip compression to have when dumping the logs (default
    # 0, no compression).

    ##
    # :attr: format
    #
    # Apache style log formatting

    ##
    # :attr: comment
    #
    # A comment about this object

    ##
    # :attr: format_version
    #
    # The version of the custom logging format used for the configured endpoint.
    # Can be either 1 (the default, version 1 log format) or 2 (the version 2
    # log format).

    ##
    # :attr: message_type
    #
    # How the message should be formatted. Can be either classic (RFC 3164
    # syslog prefix), loggly (RFC 5424 structured syslog), logplex (Heroku-style
    # length prefixed syslog), or blank (No prefix. Useful for writing JSON and
    # CSV).

    ##
    # :attr: response_condition
    #
    # When to execute the gcs logging. If empty, always execute.

    ##
    # :attr: timestamp_format
    #
    # strftime specified timestamp formatting (default "%Y-%m-%dT%H:%M:%S.000").

    ##
    # :attr: created_at
    #
    # Timestamp when this object was created

    ##
    # :attr: updated_at
    #
    # Timestamp when this object was updated

    ##
    # :attr: deleted_at
    #
    # Timestamp when this object was deleted

    def self.path
      'logging/sumologic'
    end
  end
end
