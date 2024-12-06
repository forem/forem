require 'fog/aws/models/iam/user'

module Fog
  module AWS
    class IAM
      class Users < Fog::Collection
        attribute :is_truncated,    :aliases => 'IsTruncated'
        attribute :marker,          :aliases => 'Marker'

        model Fog::AWS::IAM::User

        def all(options = {})
          merge_attributes(options)
          data = service.list_users(options).body
          merge_attributes('IsTruncated' => data['IsTruncated'], 'Marker' => data['Marker'])
          load(data['Users']) # data is an array of attribute hashes
        end

        def current
          new(service.get_user.body['User'])
        end

        def get(identity)
          data = service.get_user(identity).body['User']
          new(data) # data is an attribute hash
        rescue Fog::AWS::IAM::NotFound
          nil
        end

        alias_method :each_user_this_page, :each

        def each
          if !block_given?
            self
          else
            subset = dup.all

            subset.each_user_this_page {|f| yield f}
            while subset.is_truncated
              subset = subset.all('Marker' => subset.marker, 'MaxItems' => 1000)
              subset.each_user_this_page {|f| yield f}
            end

            self
          end
        end
      end
    end
  end
end
