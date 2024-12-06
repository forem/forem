module Fog
  module AWS
    class Compute
      class VPC < Fog::Model
        identity :id,                :aliases => 'vpcId'

        attribute :state
        attribute :cidr_block,       :aliases => 'cidrBlock'
        attribute :dhcp_options_id,  :aliases => 'dhcpOptionsId'
        attribute :tags,             :aliases => 'tagSet'
        attribute :tenancy,          :aliases => 'instanceTenancy'
        attribute :is_default,       :aliases => 'isDefault'

        attribute :cidr_block_association_set, :aliases => 'cidrBlockAssociationSet'

        attribute :ipv6_cidr_block_association_set, :aliases => 'ipv6CidrBlockAssociationSet'
        attribute :amazon_provided_ipv6_cidr_block, :aliases => 'amazonProvidedIpv6CidrBlock'

        # Backward compatibility. Please use ipv6_cidr_block_association_set
        alias_method :ipv_6_cidr_block_association_set,  :ipv6_cidr_block_association_set
        alias_method :ipv_6_cidr_block_association_set=, :ipv6_cidr_block_association_set=
        alias_method :amazon_provided_ipv_6_cidr_block,  :amazon_provided_ipv6_cidr_block
        alias_method :amazon_provided_ipv_6_cidr_block=, :amazon_provided_ipv6_cidr_block=

        def subnets
          service.subnets(:filters => {'vpcId' => self.identity}).all
        end

        def initialize(attributes={})
          self.dhcp_options_id ||= "default"
          self.tenancy ||= "default"
          self.amazon_provided_ipv_6_cidr_block ||=false
          super
        end

        def ready?
          requires :state
          state == 'available'
        end

        def is_default?
          requires :is_default
          is_default
        end

        # Removes an existing vpc
        #
        # vpc.destroy
        #
        # ==== Returns
        #
        # True or false depending on the result
        #

        def destroy
          requires :id

          service.delete_vpc(id)
          true
        end

        def classic_link_enabled?
          requires :identity
          service.describe_vpc_classic_link(:vpc_ids => [self.identity]).body['vpcSet'].first['classicLinkEnabled']
        rescue
          nil
        end

        def enable_classic_link
          requires :identity
          service.enable_vpc_classic_link(self.identity).body['return']
        end

        def disable_classic_link
          requires :identity
          service.disable_vpc_classic_link(self.identity).body['return']
        end

        def classic_link_dns_enabled?
          requires :identity
          service.describe_vpc_classic_link_dns_support(:vpc_ids => [self.identity]).body['vpcs'].first['classicLinkDnsSupported']
        rescue
          nil
        end

        def enable_classic_link_dns
          requires :identity
          service.enable_vpc_classic_link_dns_support(self.identity).body['return']
        end

        def disable_classic_link_dns
          requires :identity
          service.disable_vpc_classic_link_dns_support(self.identity).body['return']
        end

        # Create a vpc
        #
        # >> g = AWS.vpcs.new(:cidr_block => "10.1.2.0/24")
        # >> g.save
        #
        # == Returns:
        #
        # True or an exception depending on the result. Keep in mind that this *creates* a new vpc.
        # As such, it yields an InvalidGroup.Duplicate exception if you attempt to save an existing vpc.
        #

        def save
          requires :cidr_block

          options = {
            'AmazonProvidedIpv6CidrBlock' => amazon_provided_ipv_6_cidr_block,
            'InstanceTenancy' => tenancy
          }

          data = service.create_vpc(cidr_block, options).body['vpcSet'].first
          new_attributes = data.reject {|key,value| key == 'requestId'}
          new_attributes = data.reject {|key,value| key == 'requestId' || key == 'tagSet' }
          merge_attributes(new_attributes)

          if tags = self.tags
            # expect eventual consistency
            Fog.wait_for { self.reload rescue nil }
            service.create_tags(
              self.identity,
              tags
            )
          end

          true
        end
      end
    end
  end
end
