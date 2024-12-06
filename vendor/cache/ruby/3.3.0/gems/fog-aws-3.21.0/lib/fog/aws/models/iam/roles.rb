require 'fog/aws/models/iam/role'

module Fog
  module AWS
    class IAM
      class Roles < Fog::AWS::IAM::PagedCollection

        model Fog::AWS::IAM::Role

        def all(options={})
          body = service.list_roles(page_params(options)).body

          merge_attributes(body)
          load(body["Roles"])
        end

        def get(identity)
          new(service.get_role(identity).body["Role"])
        rescue Excon::Errors::NotFound, Fog::AWS::IAM::NotFound
          nil
        end

        def new(attributes = {})
          unless attributes.key?(:assume_role_policy_document)
            attributes[:assume_role_policy_document] = Fog::AWS::IAM::EC2_ASSUME_ROLE_POLICY.to_s
          end

          super
        end
      end
    end
  end
end
