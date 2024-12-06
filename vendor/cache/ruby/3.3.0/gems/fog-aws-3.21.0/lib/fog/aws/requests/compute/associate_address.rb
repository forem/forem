module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/associate_address'

        # Associate an elastic IP address with an instance
        #
        # ==== Parameters
        # * instance_id<~String> - Id of instance to associate address with (conditional)
        # * public_ip<~String> - Public ip to assign to instance (conditional)
        # * network_interface_id<~String> - Id of a nic to associate address with (required in a vpc instance with more than one nic) (conditional)
        # * allocation_id<~String> - Allocation Id to associate address with (vpc only) (conditional)
        # * private_ip_address<~String> - Private Ip Address to associate address with (vpc only)
        # * allow_reassociation<~Boolean> - Allows an elastic ip address to be reassigned  (vpc only) (conditional)
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #     * 'associationId'<~String> - association Id for eip to node (vpc only)
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AssociateAddress.html]
        def associate_address(*args)
          if args.first.kind_of? Hash
            params = args.first
          else
            params = {
                :instance_id => args[0],
                :public_ip => args[1],
                :network_interface_id => args[2],
                :allocation_id => args[3],
                :private_ip_address => args[4],
                :allow_reassociation => args[5],
            }
          end
          # Cannot specify an allocation ip and a public IP at the same time.  If you have an allocation Id presumably you are in a VPC
          # so we will null out the public IP
          params[:public_ip] = params[:allocation_id].nil? ? params[:public_ip] : nil

          request(
            'Action'             => 'AssociateAddress',
            'AllocationId'       => params[:allocation_id],
            'InstanceId'         => params[:instance_id],
            'NetworkInterfaceId' => params[:network_interface_id],
            'PublicIp'           => params[:public_ip],
            'PrivateIpAddress'   => params[:private_ip_address],
            'AllowReassociation' => params[:allow_reassociation],
            :idempotent          => true,
            :parser              => Fog::Parsers::AWS::Compute::AssociateAddress.new
          )
        end
      end

      class Mock
        def associate_address(*args)
          if args.first.kind_of? Hash
            params = args.first
          else
            params = {
                :instance_id => args[0],
                :public_ip => args[1],
                :network_interface_id => args[2],
                :allocation_id => args[3],
                :private_ip_address => args[4],
                :allow_reassociation => args[5],
            }
          end
          params[:public_ip] = params[:allocation_id].nil? ? params[:public_ip] : nil
          response = Excon::Response.new
          response.status = 200
          instance = self.data[:instances][params[:instance_id]]
         # address =  self.data[:addresses][params[:public_ip]]
          address = params[:public_ip].nil? ? nil : self.data[:addresses][params[:public_ip]]
          # This is a classic server, a VPC with a single network interface id or a VPC with multiple network interfaces one of which is specified
          if ((instance && address) || (instance &&  !params[:allocation_id].nil?) || (!params[:allocation_id].nil? && !network_interface_id.nil?))
            if !params[:allocation_id].nil?
              allocation_ip = describe_addresses( 'allocation-id'  => "#{params[:allocation_id]}").body['addressesSet'].first
              if !allocation_ip.nil?
                public_ip = allocation_ip['publicIp']
                address = public_ip.nil? ? nil : self.data[:addresses][public_ip]

                if instance['vpcId'] && vpc = self.data[:vpcs].detect { |v| v['vpcId'] == instance['vpcId'] }
                  if vpc['enableDnsHostnames']
                    instance['dnsName'] = Fog::AWS::Mock.dns_name_for(public_ip)
                  end
                end
              end
            end
            if !address.nil?
              if current_instance = self.data[:instances][address['instanceId']]
                current_instance['ipAddress'] = current_instance['originalIpAddress']
              end
              address['instanceId'] = params[:instance_id]
            end
            # detach other address (if any)
            if self.data[:addresses][instance['ipAddress']]
              self.data[:addresses][instance['ipAddress']]['instanceId'] = nil
            end
            if !params[:public_ip].nil?
              instance['ipAddress'] = params[:public_ip]
              instance['dnsName'] = Fog::AWS::Mock.dns_name_for(params[:public_ip])
            end
            response.status = 200
            if !params[:instance_id].nil? && !params[:public_ip].nil?
              response.body = {
                'requestId' => Fog::AWS::Mock.request_id,
                'return'    => true
              }
            elsif !params[:allocation_id].nil?
              association_id = "eipassoc-#{Fog::Mock.random_hex(8)}"
              address['associationId'] = association_id
              response.body = {
                'requestId'     => Fog::AWS::Mock.request_id,
                'return'        => true,
                'associationId' => association_id,
              }
            end
            response
          elsif !instance
            raise Fog::AWS::Compute::NotFound.new("You must specify either an InstanceId or a NetworkInterfaceID")
          elsif !address
            raise Fog::AWS::Compute::Error.new("AuthFailure => The address '#{public_ip}' does not belong to you.")
          elsif params[:network_interface_id].nil? && params[:allocation_id].nil?
            raise Fog::AWS::Compute::NotFound.new("You must specify an AllocationId when specifying a NetworkInterfaceID")
          else (!instance.nil? && params[:network_interface_id].nil?) || (params[:instance_id].nil? && !params[:network_interface_id].nil?)
            raise Fog::AWS::Compute::Error.new("You must specify either an InstanceId or a NetworkInterfaceID")
          end
        end
      end
    end
  end
end
