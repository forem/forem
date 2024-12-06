require 'fog/aws/models/iam/access_key'

module Fog
  module AWS
    class IAM
      class AccessKeys < Fog::Collection
        model Fog::AWS::IAM::AccessKey

        def initialize(attributes = {})
          @username = attributes[:username]
          super
        end

        def all
          data = service.list_access_keys('UserName'=> @username).body['AccessKeys']
          load(data)
        end

        def get(identity)
          self.all.select {|access_key| access_key.id == identity}.first
        end

        def new(attributes = {})
          super({ :username => @username }.merge!(attributes))
        end
      end
    end
  end
end
