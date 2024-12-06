require 'fog/aws/models/iam/instance_profile'

module Fog
  module AWS
    class IAM
      class InstanceProfiles < Fog::AWS::IAM::PagedCollection
        model Fog::AWS::IAM::InstanceProfile

        def all(options={})
          body = service.list_instance_profiles(page_params(options)).body

          merge_attributes(body)
          load(body["InstanceProfiles"])
        end

        def get(identity)
          new(service.get_instance_profile(identity).body["Role"])
        rescue Excon::Errors::NotFound, Fog::AWS::IAM::NotFound
          nil
        end
      end
    end
  end
end
