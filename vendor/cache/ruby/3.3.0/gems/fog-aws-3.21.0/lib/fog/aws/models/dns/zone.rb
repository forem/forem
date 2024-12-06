# require 'fog/aws/models/dns/records'

module Fog
  module AWS
    class DNS
      class Zone < Fog::Model
        identity :id,                 :aliases => 'Id'

        attribute :caller_reference,  :aliases => 'CallerReference'
        attribute :change_info,       :aliases => 'ChangeInfo'
        attribute :description,       :aliases => 'Comment'
        attribute :domain,            :aliases => 'Name'
        attribute :nameservers,       :aliases => 'NameServers'

        def destroy
          requires :identity
          service.delete_hosted_zone(identity)
          true
        end

        def records
          @records ||= begin
            Fog::AWS::DNS::Records.new(
              :zone       => self,
              :service => service
            )
          end
        end

        def save
          requires :domain
          options = {}
          options[:caller_ref]  = caller_reference if caller_reference
          options[:comment]     = description if description
          data = service.create_hosted_zone(domain, options).body
          merge_attributes(data)
          true
        end

        private

        define_method(:HostedZone=) do |new_hosted_zone|
          merge_attributes(new_hosted_zone)
        end
      end
    end
  end
end
