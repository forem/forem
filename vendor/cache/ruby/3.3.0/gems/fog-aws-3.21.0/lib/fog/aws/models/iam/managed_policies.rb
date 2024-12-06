require 'fog/aws/models/iam/managed_policy'
require 'fog/aws/iam/paged_collection'

module Fog
  module AWS
    class IAM
      class ManagedPolicies < Fog::AWS::IAM::PagedCollection

        attribute :username
        attribute :group_name
        attribute :role_name

        model Fog::AWS::IAM::ManagedPolicy

        def all(options={})
          data = if self.username
                   all_by_user(self.username, options)
                 elsif self.group_name
                   all_by_group(self.group_name, options)
                 elsif self.role_name
                   all_by_role(self.role_name, options)
                 else
                   all_policies(options)
                 end

          load(data)
        end

        def get(identity)
          response = service.get_policy(identity)

          new(response.body['Policy'])
        rescue Fog::AWS::IAM::NotFound
          nil
        end

        protected

        def all_by_user(username, options={})
          body = service.list_attached_user_policies(username, page_params(options)).body
          merge_attributes(body)

          body['Policies'].map do |policy|
            service.get_policy(policy['PolicyArn']).body['Policy']
          end
        end

        def all_by_group(group_name, options={})
          body = service.list_attached_group_policies(group_name, page_params(options)).body
          merge_attributes(body)

          body['Policies'].map do |policy|
            service.get_policy(policy['PolicyArn']).body['Policy']
          end
        end

        def all_by_role(role_name, options={})
          body = service.list_attached_role_policies(role_name, page_params(options)).body
          merge_attributes(body)

          body['Policies'].map do |policy|
            service.get_policy(policy['PolicyArn']).body['Policy']
          end
        end

        def all_policies(options={})
          body = service.list_policies(page_params(options)).body
          merge_attributes(body)

          body['Policies']
        end
      end
    end
  end
end
