require 'fog/aws/models/glacier/archives'
require 'fog/aws/models/glacier/jobs'

module Fog
  module AWS
    class Glacier
      class Vault < Fog::Model
        identity  :id,                    :aliases => 'VaultName'
        attribute :created_at,            :aliases => 'CreationDate', :type => :time
        attribute :last_inventory_at,     :aliases => 'LastInventoryDate', :type => :time
        attribute :number_of_archives,    :aliases => 'NumberOfArchives', :type => :integer
        attribute :size_in_bytes,         :aliases => 'SizeInBytes', :type => :integer
        attribute :arn,                   :aliases => 'VaultARN'

        def ready?
          # Glacier requests are synchronous
          true
        end

        def archives
          @archives ||= Fog::AWS::Glacier::Archives.new(:vault => self, :service => service)
        end

        def jobs(filters={})
          Fog::AWS::Glacier::Jobs.new(:vault => self, :service => service, :filters => filters)
        end

        def set_notification_configuration(topic, events)
          service.set_vault_notification_configuration(id, topic, events)
        end

        def delete_notification_configuration
          service.delete_vault_notification_configuration(id)
        end

        def save
          requires :id
          service.create_vault(id)
          reload
        end

        def destroy
          requires :id
          service.delete_vault(id)
        end
      end
    end
  end
end
