require 'fog/aws/models/compute/server'

module Fog
  module AWS
    class Compute
      class Servers < Fog::Collection
        attribute :filters

        model Fog::AWS::Compute::Server

        # Creates a new server
        #
        # AWS.servers.new
        #
        # ==== Returns
        #
        # Returns the details of the new server
        #
        #>> AWS.servers.new
        #  <Fog::AWS::Compute::Server
        #    id=nil,
        #    ami_launch_index=nil,
        #    availability_zone=nil,
        #    block_device_mapping=nil,
        #    hibernation_options=nil,
        #    network_interfaces=nil,
        #    client_token=nil,
        #    dns_name=nil,
        #    groups=["default"],
        #    flavor_id="m1.small",
        #    image_id=nil,
        #    ip_address=nil,
        #    kernel_id=nil,
        #    key_name=nil,
        #    created_at=nil,
        #    monitoring=nil,
        #    product_codes=nil,
        #    private_dns_name=nil,
        #    private_ip_address=nil,
        #    ramdisk_id=nil,
        #    reason=nil,
        #    root_device_name=nil,
        #    root_device_type=nil,
        #    state=nil,
        #    state_reason=nil,
        #    subnet_id=nil,
        #    tags=nil,
        #    user_data=nil
        #  >
        #

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        def all(filters = self.filters)
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("all with #{filters.class} param is deprecated, use all('instance-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'instance-id' => [*filters]}
          end
          self.filters = filters
          data = service.describe_instances(filters).body
          load(
            data['reservationSet'].map do |reservation|
              reservation['instancesSet'].map do |instance|
                instance.merge(:groups => reservation['groupSet'], :security_group_ids => reservation['groupIds'])
              end
            end.flatten
          )
        end

        # Create between m and n servers with the server options specified in
        # new_attributes.  Equivalent to this loop, but happens in 1 request:
        #
        #    1.upto(n).map { create(new_attributes) }
        #
        # See the AWS RunInstances API.
        def create_many(min_servers = 1, max_servers = nil, new_attributes = {})
          max_servers ||= min_servers
          template = new(new_attributes)
          save_many(template, min_servers, max_servers)
        end

        # Bootstrap between m and n servers with the server options specified in
        # new_attributes.  Equivalent to this loop, but happens in 1 AWS request
        # and the machines' spinup will happen in parallel:
        #
        #   1.upto(n).map { bootstrap(new_attributes) }
        #
        # See the AWS RunInstances API.
        def bootstrap_many(min_servers = 1, max_servers = nil, new_attributes = {})
          template = service.servers.new(new_attributes)
          _setup_bootstrap(template)

          servers = save_many(template, min_servers, max_servers)
          servers.each do |server|
            server.wait_for { ready? }
            server.setup(:key_data => [server.private_key])
          end
          servers
        end

        def bootstrap(new_attributes = {})
          bootstrap_many(1, 1, new_attributes).first
        end

        # Used to retrieve a server
        #
        # server_id is required to get the associated server information.
        #
        # You can run the following command to get the details:
        # AWS.servers.get("i-5c973972")
        #
        # ==== Returns
        #
        #>> AWS.servers.get("i-5c973972")
        #  <Fog::AWS::Compute::Server
        #    id="i-5c973972",
        #    ami_launch_index=0,
        #    availability_zone="us-east-1b",
        #    block_device_mapping=[],
        #    hibernation_options=[],
        #    client_token=nil,
        #    dns_name="ec2-25-2-474-44.compute-1.amazonaws.com",
        #    groups=["default"],
        #    flavor_id="m1.small",
        #    image_id="test",
        #    ip_address="25.2.474.44",
        #    kernel_id="aki-4e1e1da7",
        #    key_name=nil,
        #    created_at=Mon Nov 29 18:09:34 -0500 2010,
        #    monitoring=false,
        #    product_codes=[],
        #    private_dns_name="ip-19-76-384-60.ec2.internal",
        #    private_ip_address="19.76.384.60",
        #    ramdisk_id="ari-0b3fff5c",
        #    reason=nil,
        #    root_device_name=nil,
        #    root_device_type="instance-store",
        #    state="running",
        #    state_reason={},
        #    subnet_id=nil,
        #    tags={},
        #    user_data=nil
        #  >
        #

        def get(server_id)
          if server_id
            self.class.new(:service => service).all('instance-id' => server_id).first
          end
        rescue Fog::Errors::NotFound
          nil
        end

        # From a template, create between m-n servers (see the AWS RunInstances API)
        def save_many(template, min_servers = 1, max_servers = nil)
          max_servers ||= min_servers
          data = service.run_instances(template.image_id, min_servers, max_servers, template.run_instance_options)
          # For some reason, AWS sometimes returns empty results alongside the real ones.  Thus the select
          data.body['instancesSet'].select { |instance_set| instance_set['instanceId'] }.map do |instance_set|
            server = template.dup
            server.merge_attributes(instance_set)
            # expect eventual consistency
            if (tags = server.tags) && tags.size > 0
              Fog.wait_for { server.reload rescue nil }
              Fog.wait_for {
                begin
                  service.create_tags(server.identity, tags)
                rescue Fog::AWS::Compute::NotFound
                  false
                end
              }
            end
            server
          end
        end

        private

        def _setup_bootstrap(server)
          unless server.key_name
            # first or create fog_#{credential} keypair
            name = Fog.respond_to?(:credential) && Fog.credential || :default
            unless server.key_pair = service.key_pairs.get("fog_#{name}")
              server.key_pair = service.key_pairs.create(
                :name => "fog_#{name}",
                :public_key => server.public_key
              )
            end
          end

          security_group = service.security_groups.get(server.groups.first)
          if security_group.nil?
            raise Fog::AWS::Compute::Error, "The security group" \
              " #{server.groups.first} doesn't exist."
          end

          # make sure port 22 is open in the first security group
          authorized = security_group.ip_permissions.find do |ip_permission|
            ip_permission['ipRanges'].find { |ip_range| ip_range['cidrIp'] == '0.0.0.0/0' } &&
            ip_permission['fromPort'] == 22 &&
            ip_permission['ipProtocol'] == 'tcp' &&
            ip_permission['toPort'] == 22
          end

          unless authorized
            security_group.authorize_port_range(22..22)
          end
        end
      end
    end
  end
end
