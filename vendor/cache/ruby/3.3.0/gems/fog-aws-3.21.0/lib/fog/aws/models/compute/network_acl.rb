module Fog
  module AWS
    class Compute
      class NetworkAcl < Fog::Model
        ICMP = 1
        TCP  = 6
        UDP  = 17

        identity  :network_acl_id, :aliases => 'networkAclId'
        attribute :vpc_id,         :aliases => 'vpcId'
        attribute :default
        attribute :entries,        :aliases => 'entrySet'
        attribute :associations,   :aliases => 'associationSet'
        attribute :tags,           :aliases => 'tagSet'

        # Add an inbound rule, shortcut method for #add_rule
        def add_inbound_rule(rule_number, protocol, rule_action, cidr_block, options = {})
          add_rule(rule_number, protocol, rule_action, cidr_block, false, options)
        end

        # Add an outbound rule, shortcut method for #add_rule
        def add_outbound_rule(rule_number, protocol, rule_action, cidr_block, options = {})
          add_rule(rule_number, protocol, rule_action, cidr_block, true, options)
        end

        # Add a new rule
        #
        # network_acl.add_rule(100, Fog::AWS::Compute::NetworkAcl::TCP, 'allow', '0.0.0.0/0', true, 'PortRange.From' => 22, 'PortRange.To' => 22)
        #
        # ==== Parameters
        # * rule_number<~Integer>   - The rule number for the entry, between 100 and 32766
        # * protocol<~Integer>      - The IP protocol to which the rule applies. You can use -1 to mean all protocols.
        # * rule_action<~String>    - Allows or denies traffic that matches the rule. (either allow or deny)
        # * cidr_block<~String>     - The CIDR range to allow or deny
        # * egress<~Boolean>        - Indicates whether this rule applies to egress traffic from the subnet (true) or ingress traffic to the subnet (false).
        # * options<~Hash>:
        # *   'Icmp.Code'           - ICMP code, required if protocol is 1
        # *   'Icmp.Type'           - ICMP type, required if protocol is 1
        # *   'PortRange.From'      - The first port in the range, required if protocol is 6 (TCP) or 17 (UDP)
        # *   'PortRange.To'        - The last port in the range, required if protocol is 6 (TCP) or 17 (UDP)
        #
        # ==== Returns
        #
        # True or false depending on the result
        #
        def add_rule(rule_number, protocol, rule_action, cidr_block, egress, options = {})
          requires :network_acl_id

          service.create_network_acl_entry(network_acl_id, rule_number, protocol, rule_action, cidr_block, egress, options)
          true
        end

        # Remove an inbound rule, shortcut method for #remove_rule
        def remove_inbound_rule(rule_number)
          remove_rule(rule_number, false)
        end

        # Remove an outbound rule, shortcut method for #remove_rule
        def remove_outbound_rule(rule_number)
          remove_rule(rule_number, true)
        end

        # Update a specific rule number
        #
        # network_acl.remove_rule(100, true)
        #
        # ==== Parameters
        # * rule_number<~Integer>   - The rule number for the entry, between 100 and 32766
        # * egress<~Boolean>        - Indicates whether this rule applies to egress traffic from the subnet (true) or ingress traffic to the subnet (false).
        #
        # ==== Returns
        #
        # True or false depending on the result
        #
        def remove_rule(rule_number, egress)
          requires :network_acl_id

          service.delete_network_acl_entry(network_acl_id, rule_number, egress)
          true
        end

        # Update an inbound rule, shortcut method for #update_rule
        def update_inbound_rule(rule_number, protocol, rule_action, cidr_block, options = {})
          update_rule(rule_number, protocol, rule_action, cidr_block, false, options)
        end

        # Update an outbound rule, shortcut method for #update_rule
        def update_outbound_rule(rule_number, protocol, rule_action, cidr_block, options = {})
          update_rule(rule_number, protocol, rule_action, cidr_block, true, options)
        end

        # Update a specific rule number
        #
        # network_acl.update_rule(100, Fog::AWS::Compute::NetworkAcl::TCP, 'allow', '0.0.0.0/0', true, 'PortRange.From' => 22, 'PortRange.To' => 22)
        #
        # ==== Parameters
        # * rule_number<~Integer>   - The rule number for the entry, between 100 and 32766
        # * protocol<~Integer>      - The IP protocol to which the rule applies. You can use -1 to mean all protocols.
        # * rule_action<~String>    - Allows or denies traffic that matches the rule. (either allow or deny)
        # * cidr_block<~String>     - The CIDR range to allow or deny
        # * egress<~Boolean>        - Indicates whether this rule applies to egress traffic from the subnet (true) or ingress traffic to the subnet (false).
        # * options<~Hash>:
        # *   'Icmp.Code'           - ICMP code, required if protocol is 1
        # *   'Icmp.Type'           - ICMP type, required if protocol is 1
        # *   'PortRange.From'      - The first port in the range, required if protocol is 6 (TCP) or 17 (UDP)
        # *   'PortRange.To'        - The last port in the range, required if protocol is 6 (TCP) or 17 (UDP)
        #
        # ==== Returns
        #
        # True or false depending on the result
        #
        def update_rule(rule_number, protocol, rule_action, cidr_block, egress, options = {})
          requires :network_acl_id

          service.replace_network_acl_entry(network_acl_id, rule_number, protocol, rule_action, cidr_block, egress, options)
          true
        end

        # Associate a subnet with this network ACL
        #
        # network_acl.associate_with(subnet)
        #
        # ==== Parameters
        # * subnet<~Subnet> - Subnet object to associate with this network ACL
        #
        # ==== Returns
        #
        # True or false depending on the result
        #
        def associate_with(subnet)
          requires :network_acl_id

          # We have to manually find out the network ACL the subnet is currently associated with
          old_id = service.network_acls.all('association.subnet-id' => subnet.subnet_id).first.associations.find { |a| a['subnetId'] == subnet.subnet_id }['networkAclAssociationId']
          service.replace_network_acl_association(old_id, network_acl_id)
          true
        end

        # Removes an existing network ACL
        #
        # network_acl.destroy
        #
        # ==== Returns
        #
        # True or false depending on the result
        #
        def destroy
          requires :network_acl_id

          service.delete_network_acl(network_acl_id)
          true
        end

        # Create a network ACL
        #
        #  >> g = AWS.network_acls.new(:vpc_id => 'vpc-abcdefgh')
        #  >> g.save
        def save
          requires :vpc_id
          data = service.create_network_acl(vpc_id).body['networkAcl']
          new_attributes = data.reject { |key,value| key == 'tagSet' }
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
