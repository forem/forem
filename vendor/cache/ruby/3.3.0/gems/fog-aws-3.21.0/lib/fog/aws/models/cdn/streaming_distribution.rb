require 'fog/aws/models/cdn/invalidations'
require 'fog/aws/models/cdn/distribution_helper'

module Fog
  module AWS
    class CDN
      class StreamingDistribution < Fog::Model
        include Fog::AWS::CDN::DistributionHelper

        identity :id,                 :aliases => 'Id'

        attribute :caller_reference,   :aliases => 'CallerReference'
        attribute :last_modified_time, :aliases => 'LastModifiedTime'
        attribute :status,             :aliases => 'Status'
        attribute :s3_origin,          :aliases => 'S3Origin'
        attribute :cname,              :aliases => 'CNAME'
        attribute :comment,            :aliases => 'Comment'
        attribute :enabled,            :aliases => 'Enabled'
        attribute :logging,            :aliases => 'Logging'
        attribute :domain,             :aliases => 'DomainName'
        attribute :etag,               :aliases => ['Etag', 'ETag']

        # items part of DistributionConfig
        CONFIG = [ :caller_reference, :cname, :comment, :enabled, :logging ]

        def initialize(new_attributes = {})
          super(distribution_config_to_attributes(new_attributes))
        end

        def save
          requires_one :s3_origin
          options = attributes_to_options
          response = identity ? put_distribution_config(identity, etag, options) : post_distribution(options)
          etag = response.headers['ETag']
          merge_attributes(response.body)
          true
        end

        private

        def delete_distribution(identity, etag)
          service.delete_streaming_distribution(identity, etag)
        end

        def put_distribution_config(identity, etag, options)
          service.put_streaming_distribution_config(identity, etag, options)
        end

        def post_distribution(options = {})
          service.post_streaming_distribution(options)
        end

        def attributes_to_options
          options = {
            'CallerReference' => caller_reference,
            'S3Origin' => s3_origin,
            'CNAME' => cname,
            'Comment' => comment,
            'Enabled' => enabled,
            'Logging' => logging,
          }
          options.reject! { |k,v| v.nil? }
          options.reject! { |k,v| v.respond_to?(:empty?) && v.empty? }
          options
        end

        def distribution_config_to_attributes(new_attributes = {})
          new_attributes.merge(new_attributes.delete('StreamingDistributionConfig') || {})
        end
      end
    end
  end
end
