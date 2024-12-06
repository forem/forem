require 'fog/aws/models/glacier/archive'

module Fog
  module AWS
    class Glacier
      class Archives < Fog::Collection
        model Fog::AWS::Glacier::Archive
        attribute :vault
        #you can't list a vault's archives
        def all
          nil
        end

        def get(key)
          new(:id => key)
        end

        def new(attributes = {})
          requires :vault
          super({ :vault => vault }.merge!(attributes))
        end
      end
    end
  end
end
