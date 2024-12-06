require 'fog/aws/models/cdn/invalidations'
require 'fog/aws/models/cdn/distribution_helper'

module Fog
  module AWS
    class CDN
      class Distribution < Fog::Model
        include Fog::AWS::CDN::DistributionHelper

        identity :id,                 :aliases => 'Id'

        attribute :caller_reference,   :aliases => 'CallerReference'
        attribute :last_modified_time, :aliases => 'LastModifiedTime'
        attribute :status,             :aliases => 'Status'
        attribute :s3_origin,          :aliases => 'S3Origin'
        attribute :custom_origin,      :aliases => 'CustomOrigin'
        attribute :cname,              :aliases => 'CNAME'
        attribute :comment,            :aliases => 'Comment'
        attribute :enabled,            :aliases => 'Enabled'
        attribute :in_progress_invalidation_batches, :aliases => 'InProgressInvalidationBatches'
        attribute :logging,            :aliases => 'Logging'
        attribute :trusted_signers,    :aliases => 'TrustedSigners'
        attribute :default_root_object,:aliases => 'DefaultRootObject'
        attribute :domain,             :aliases => 'DomainName'
        attribute :etag,               :aliases => ['Etag', 'ETag']

        # items part of DistributionConfig
        CONFIG = [ :caller_reference, :origin,  :cname, :comment, :enabled, :logging, :trusted_signers, :default_root_object ]

        def initialize(new_attributes = {})
          super(distribution_config_to_attributes(new_attributes))
        end

        def invalidations
          @invalidations ||= begin
            Fog::AWS::CDN::Invalidations.new(
              :distribution => self,
              :service => service
            )
          end
        end

        def save
          requires_one :s3_origin, :custom_origin
          options = attributes_to_options
          response = identity ? put_distribution_config(identity, etag, options) : post_distribution(options)
          etag = response.headers['ETag']
          merge_attributes(response.body)
          true
        end

        private

        def delete_distribution(identity, etag)
          service.delete_distribution(identity, etag)
        end

        def put_distribution_config(identity, etag, options)
          service.put_distribution_config(identity, etag, options)
        end

        def post_distribution(options = {})
          service.post_distribution(options)
        end

        def attributes_to_options
          options = {
            'CallerReference' => caller_reference,
            'S3Origin' => s3_origin,
            'CustomOrigin' => custom_origin,
            'CNAME' => cname,
            'Comment' => comment,
            'Enabled' => enabled,
            'Logging' => logging,
            'TrustedSigners' => trusted_signers,
            'DefaultRootObject' => default_root_object
          }
          options.reject! { |k,v| v.nil? }
          options.reject! { |k,v| v.respond_to?(:empty?) && v.empty? }
          options
        end

        def distribution_config_to_attributes(new_attributes = {})
          new_attributes.merge(new_attributes.delete('DistributionConfig') || {})
        end
      end
    end
  end
end
