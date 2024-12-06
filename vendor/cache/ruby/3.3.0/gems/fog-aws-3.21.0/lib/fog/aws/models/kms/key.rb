module Fog
  module AWS
    class KMS
      class Key < Fog::Model
        identity :id, :aliases => 'KeyId'

        attribute :account_id,  :aliases => 'AWSAccountId'
        attribute :arn,         :aliases => 'KeyArn'
        attribute :created_at,  :aliases => 'CreationDate', :type => :time
        attribute :description, :aliases => 'Description'
        attribute :enabled,     :aliases => 'Enabled', :type => :boolean
        attribute :usage,       :aliases => 'KeyUsage'

        attr_writer :policy

        def reload
          requires :identity

          data = service.describe_key(self.identity)
          merge_attributes(data.body['KeyMetadata'])

          self
        end

        def save
          data = service.create_key(@policy, description, usage)

          merge_attributes(data.body['KeyMetadata'])
          true
        end
      end
    end
  end
end
