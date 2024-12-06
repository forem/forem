module Fog
  module AWS
    class IAM
      class ManagedPolicy < Fog::Model
        identity  :id, :aliases => 'PolicyId'

        attribute :arn,             :aliases => 'Arn'
        attribute :attachable,      :aliases => 'IsAttachable', :type => :boolean
        attribute :attachments,     :aliases => 'AttachmentCount', :type => :integer
        attribute :created_at,      :aliases => 'CreateDate', :type => :time
        attribute :default_version, :aliases => 'DefaultVersionId'
        attribute :description,     :aliases => 'Description'
        attribute :name,            :aliases => 'PolicyName'
        attribute :path,            :aliases => 'Path'
        attribute :updated_at,      :aliases => 'UpdateDate', :type => :time

        attr_accessor :policy_document

        def attach(user_or_username)
          requires :arn

          username = if user_or_username.respond_to?(:identity)
                       user_or_username.identity
                     else
                       user_or_username
                     end

          service.attach_user_policy(username, self.arn)
        end

        def document
          requires :arn, :default_version

          service.get_policy_version(self.arn, self.default_version).
            body['PolicyVersion']['Document']
        end

        def reload
          service.managed_policies.get(self.arn)
        end

        def save
          requires :name, :policy_document

          merge_attributes(service.create_policy(self.name, self.policy_document, self.path, self.description).body["Policy"])
        end

        def destroy
          requires :arn

          service.delete_policy(self.arn)

          true
        end
      end
    end
  end
end
