module Fog
  module AWS
    class IAM
      class AccessKey < Fog::Model
        identity  :id, :aliases => 'AccessKeyId'
        attribute :username, :aliases => 'UserName'
        attribute :secret_access_key, :aliases => 'SecretAccessKey'
        attribute :status, :aliases => 'Status'

        def save
          requires :username

          if !persisted?
            data = service.create_access_key('UserName'=> username).body["AccessKey"]
          else
            data = service.update_access_key(id, status, "UserName" => username).body["AccessKey"]
          end
          merge_attributes(data)
          true
        end

        def destroy
          requires :id
          requires :username

          service.delete_access_key(id,'UserName'=> username)
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
