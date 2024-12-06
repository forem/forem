class Fastly
  # An Google BigQuery endpoint to stream logs to
  class BigQueryLogging < BelongsToServiceAndVersion
    attr_accessor :created_at, :dataset, :format, :format_version, :name, :placement, :project_id,
                  :response_condition, :secret_key, :service_id, :table, :template_suffix,
                  :updated_at, :user

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
    # The name for this BigQuery logging rule

    ##
    # :attr: project_id
    #
    # The Google Cloud project ID

    ##
    # :attr: dataset
    #
    # The BigQuery dataset name

    ##
    # :attr: table
    #
    # The BigQuery table name

    ##
    # :attr: template_suffix
    #
    # The BigQuery template-table suffix. Null for non-templated tables.
    # See https://cloud.google.com/bigquery/streaming-data-into-bigquery#template-tables

    ##
    # :attr: user
    #
    # The gcs user for authentication

    ##
    # :attr: secret_key
    #
    # The bucket's gcs account secret key

    ##
    # :attr: placement
    #
    # Where in the generated VCL the logging call should be placed

    ##
    # :attr: format
    #
    # JSON data structure with VCL interpolations.

    ##
    # :attr: format_version
    #
    # The version of the custom logging format used for the configured endpoint.
    # Can be either 1 (the default, version 1 log format) or 2 (the version 2
    # log format).

    ##
    # :attr: response_condition
    #
    # When to execute the gcs logging. If empty, always execute.

    ##
    # :attr: created_at
    #
    # Timestamp when this object was created

    ##
    # :attr: updated_at
    #
    # Timestamp when this object was updated

    def self.path
      'logging/bigquery'
    end
  end
end
