class Fastly
  # An s3 endpoint to stream logs to
  class S3Logging < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :bucket_name, :access_key, :secret_key, :path, :period, :gzip_level, :format, :format_version, :message_type, :response_condition, :timestamp_format, :domain, :redundancy

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
    # :attr: bucket_name
    #
    # The name of the s3 bucket

    ##
    # :attr: access_key
    #
    # The bucket's s3 account access key

    ##
    # :attr: secret_key
    #
    # The bucket's s3 account secret key

    ##
    # :attr: path
    #
    # The path to upload logs to

    ##
    # :attr: period
    #
    # How frequently the logs should be dumped (in seconds, default 3600)

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
    # When to execute the s3 logging. If empty, always execute.

    ##
    # :attr: timestamp_format
    #
    # strftime specified timestamp formatting (default "%Y-%m-%dT%H:%M:%S.000").

    ##
    # :attr: domain
    #
    # The region-specific endpoint for your domain if your AWS S3 bucket was not
    # set up in the US Standard region. See Amazon's list of supported,
    # region-specific endpoints for more info.
    # http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region

    ##
    # :attr: redundancy
    #
    # The S3 redundancy level. Defaults to Standard. See
    # http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingRRS.html  on using reduced
    # redundancy storage for more information.

    def self.path
      'logging/s3'
    end
  end
end
