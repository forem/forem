module Fog
  module AWS
    class CDN
      module DistributionHelper
        def destroy
          requires :identity, :etag, :caller_reference
          raise "Distribution must be disabled to be deleted" unless disabled?
          delete_distribution(identity, etag)
          true
        end

        def enabled?
          requires :identity
          !!enabled and ready?
        end

        def disabled?
          requires :identity
          not enabled? and ready?
        end

        def custom_origin?
          requires :identity
          not custom_origin.nil?
        end

        def ready?
          requires :identity
          status == 'Deployed'
        end

        def enable
          requires :identity
          reload if etag.nil? or caller_reference.nil?
          unless enabled?
            self.enabled = true
            response = put_distribution_config(identity, etag, attributes_to_options)
            etag = response.headers['ETag']
            merge_attributes(response.body)
          end
          true
        end

        def disable
          requires :identity
          reload if etag.nil? or caller_reference.nil?
          if enabled?
            self.enabled = false
            response = put_distribution_config(identity, etag, attributes_to_options)
            etag = response.headers['ETag']
            merge_attributes(response.body)
          end
          true
        end
      end
    end
  end
end
