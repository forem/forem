module Fog
  module AWS
    class IAM
      class Policy < Fog::Model
        identity  :id, :aliases => 'PolicyName'
        attribute :username, :aliases => 'UserName'
        attribute :document, :aliases => 'PolicyDocument'

        attr_accessor :group_name

        def save
          requires :id
          requires_one :username, :group_name
          requires :document

          data = if username
                   service.put_user_policy(username, id, document).body
                 else
                   service.put_group_policy(group_name, id, document).body
                 end

          merge_attributes(data)
          true
        end

        def destroy
          requires :id
          requires :username

          service.delete_user_policy(username, id)
          true
        end

        def user
          requires :username
          service.users.get(username)
        end
      end
    end
  end
end
