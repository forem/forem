require 'fog/aws/models/iam/policy'
require 'fog/aws/iam/paged_collection'

module Fog
  module AWS
    class IAM
      class Policies < Fog::AWS::IAM::PagedCollection

        model Fog::AWS::IAM::Policy

        attribute :username
        attribute :group_name

        def all(options={})
          requires_one :username, :group_name

          policies = if self.username
                       all_by_user(self.username, options)
                     else self.group_name
                       all_by_group(self.group_name, options)
                     end

          load(policies) # data is an array of attribute hashes
        end

        def get(identity)
          requires_one :username, :group_name

          response = if self.username
                       service.get_user_policy(identity, self.username)
                     else self.group_name
                       service.get_group_policy(identity, self.group_name)
                     end

          new(response.body['Policy'])
        rescue Fog::AWS::IAM::NotFound
          nil
        end

        def new(attributes = {})
          super(self.attributes.merge(attributes))
        end

        private

        # AWS method get_user_policy and list_group_policies only returns an array of policy names, this is kind of useless,
        # that's why it has to loop through the list to get the details of each element. I don't like it because it makes this method slow

        def all_by_group(group_name, options={})
          response = service.list_group_policies(group_name, page_params(options))
          merge_attributes(response.body)

          response.body['PolicyNames'].map do |policy_name|
            service.get_group_policy(policy_name, group_name).body['Policy']
          end
        end

        def all_by_user(username, options={})
          response = service.list_user_policies(username, page_params(options))
          merge_attributes(response.body)

          response.body['PolicyNames'].map do |policy_name|
            service.get_user_policy(policy_name, username).body['Policy']
          end
        end
      end
    end
  end
end
