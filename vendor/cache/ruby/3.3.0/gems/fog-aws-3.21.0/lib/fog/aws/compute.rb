module Fog
  module AWS
    class Compute < Fog::Service
      extend Fog::AWS::CredentialFetcher::ServiceMethods

      class RequestLimitExceeded < Fog::Errors::Error; end

      requires :aws_access_key_id, :aws_secret_access_key
      recognizes :endpoint, :region, :host, :path, :port, :scheme, :persistent, :aws_session_token, :use_iam_profile, :aws_credentials_expire_at, :instrumentor, :instrumentor_name, :version, :retry_request_limit_exceeded, :retry_jitter_magnitude, :sts_endpoint

      secrets    :aws_secret_access_key, :hmac, :aws_session_token

      model_path 'fog/aws/models/compute'
      model       :address
      collection  :addresses
      model       :dhcp_options
      collection  :dhcp_options
      model       :flavor
      collection  :flavors
      model       :image
      collection  :images
      model       :internet_gateway
      collection  :internet_gateways
      model       :key_pair
      collection  :key_pairs
      model       :network_acl
      collection  :network_acls
      model       :network_interface
      collection  :network_interfaces
      model       :route_table
      collection  :route_tables
      model       :security_group
      collection  :security_groups
      model       :server
      collection  :servers
      model       :snapshot
      collection  :snapshots
      model       :tag
      collection  :tags
      model       :volume
      collection  :volumes
      model       :spot_request
      collection  :spot_requests
      model       :subnet
      collection  :subnets
      model       :vpc
      collection  :vpcs

      request_path 'fog/aws/requests/compute'
      request :allocate_address
      request :assign_private_ip_addresses
      request :associate_address
      request :associate_dhcp_options
      request :attach_network_interface
      request :associate_route_table
      request :attach_classic_link_vpc
      request :attach_internet_gateway
      request :attach_volume
      request :authorize_security_group_egress
      request :authorize_security_group_ingress
      request :cancel_spot_instance_requests
      request :create_dhcp_options
      request :create_internet_gateway
      request :create_image
      request :create_key_pair
      request :create_network_acl
      request :create_network_acl_entry
      request :create_network_interface
      request :create_placement_group
      request :create_route
      request :create_route_table
      request :create_security_group
      request :create_snapshot
      request :create_spot_datafeed_subscription
      request :create_subnet
      request :create_tags
      request :create_volume
      request :create_vpc
      request :copy_image
      request :copy_snapshot
      request :delete_dhcp_options
      request :delete_internet_gateway
      request :delete_key_pair
      request :delete_network_acl
      request :delete_network_acl_entry
      request :delete_network_interface
      request :delete_security_group
      request :delete_placement_group
      request :delete_route
      request :delete_route_table
      request :delete_snapshot
      request :delete_spot_datafeed_subscription
      request :delete_subnet
      request :delete_tags
      request :delete_volume
      request :delete_vpc
      request :deregister_image
      request :describe_account_attributes
      request :describe_addresses
      request :describe_availability_zones
      request :describe_classic_link_instances
      request :describe_dhcp_options
      request :describe_images
      request :describe_image_attribute
      request :describe_instances
      request :describe_instance_attribute
      request :describe_internet_gateways
      request :describe_reserved_instances
      request :describe_instance_status
      request :describe_key_pairs
      request :describe_network_acls
      request :describe_network_interface_attribute
      request :describe_network_interfaces
      request :describe_route_tables
      request :describe_placement_groups
      request :describe_regions
      request :describe_reserved_instances_offerings
      request :describe_security_groups
      request :describe_snapshots
      request :describe_spot_datafeed_subscription
      request :describe_spot_instance_requests
      request :describe_spot_price_history
      request :describe_subnets
      request :describe_tags
      request :describe_volumes
      request :describe_volumes_modifications
      request :describe_volume_status
      request :describe_vpcs
      request :describe_vpc_attribute
      request :describe_vpc_classic_link
      request :describe_vpc_classic_link_dns_support
      request :detach_network_interface
      request :detach_internet_gateway
      request :detach_volume
      request :detach_classic_link_vpc
      request :disable_vpc_classic_link
      request :disable_vpc_classic_link_dns_support
      request :disassociate_address
      request :disassociate_route_table
      request :enable_vpc_classic_link
      request :enable_vpc_classic_link_dns_support
      request :get_console_output
      request :get_password_data
      request :import_key_pair
      request :modify_image_attribute
      request :modify_instance_attribute
      request :modify_instance_placement
      request :modify_network_interface_attribute
      request :modify_snapshot_attribute
      request :modify_subnet_attribute
      request :modify_volume
      request :modify_volume_attribute
      request :modify_vpc_attribute
      request :move_address_to_vpc
      request :purchase_reserved_instances_offering
      request :reboot_instances
      request :release_address
      request :replace_network_acl_association
      request :replace_network_acl_entry
      request :replace_route
      request :register_image
      request :request_spot_instances
      request :reset_network_interface_attribute
      request :restore_address_to_classic
      request :revoke_security_group_egress
      request :revoke_security_group_ingress
      request :run_instances
      request :terminate_instances
      request :start_instances
      request :stop_instances
      request :monitor_instances
      request :unmonitor_instances

      class InvalidURIError < Exception; end

      # deprecation
      class Real
        def modify_image_attributes(*params)
          Fog::Logger.deprecation("modify_image_attributes is deprecated, use modify_image_attribute instead [light_black](#{caller.first})[/]")
          modify_image_attribute(*params)
        end

        # http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-supported-platforms.html
        def supported_platforms
          describe_account_attributes.body["accountAttributeSet"].find{ |h| h["attributeName"] == "supported-platforms" }["values"]
        end
      end

      class Mock
        MOCKED_TAG_TYPES = {
          'acl'  => 'network_acl',
          'ami'  => 'image',
          'igw'  => 'internet_gateway',
          'i'    => 'instance',
          'rtb'  => 'route_table',
          'snap' => 'snapshot',
          'vol'  => 'volume',
          'vpc'  => 'vpc'
        }

        VPC_BLANK_VALUE = 'none'

        include Fog::AWS::CredentialFetcher::ConnectionMethods

        def self.data
          @data ||= Hash.new do |hash, region|
            hash[region] = Hash.new do |region_hash, key|
              owner_id = Fog::AWS::Mock.owner_id
              security_group_id = Fog::AWS::Mock.security_group_id
              region_hash[key] = {
                :deleted_at => {},
                :addresses  => {},
                :images     => {},
                :image_launch_permissions => Hash.new do |permissions_hash, image_key|
                  permissions_hash[image_key] = {
                    :users => []
                  }
                end,
                :instances  => {},
                :reserved_instances => {},
                :key_pairs  => {},
                :limits     => { :addresses => 5 },
                :owner_id   => owner_id,
                :security_groups => {
                  'default' => {
                    'groupDescription'    => 'default group',
                    'groupName'           => 'default',
                    'groupId'             => security_group_id,
                    'ipPermissionsEgress' => [],
                    'ipPermissions'       => [
                      {
                        'groups'      => [{'groupName' => 'default', 'userId' => owner_id, 'groupId' => security_group_id }],
                        'fromPort'    => -1,
                        'toPort'      => -1,
                        'ipProtocol'  => 'icmp',
                        'ipRanges'    => [],
                        'ipv6Ranges'  => []
                      },
                      {
                        'groups'      => [{'groupName' => 'default', 'userId' => owner_id, 'groupId' => security_group_id}],
                        'fromPort'    => 0,
                        'toPort'      => 65535,
                        'ipProtocol'  => 'tcp',
                        'ipRanges'    => [],
                        'ipv6Ranges'  => []
                      },
                      {
                        'groups'      => [{'groupName' => 'default', 'userId' => owner_id, 'groupId' => security_group_id}],
                        'fromPort'    => 0,
                        'toPort'      => 65535,
                        'ipProtocol'  => 'udp',
                        'ipRanges'    => [],
                        'ipv6Ranges'  => []
                      }
                    ],
                    'ownerId'             => owner_id
                  },
                  'amazon-elb-sg' => {
                    'groupDescription'   => 'amazon-elb-sg',
                    'groupName'          => 'amazon-elb-sg',
                    'groupId'            => 'amazon-elb',
                    'ownerId'            => 'amazon-elb',
                    'ipPermissionsEgree' => [],
                    'ipPermissions'      => [],
                  },
                },
                :network_acls => {},
                :network_interfaces => {},
                :snapshots => {},
                :volumes => {},
                :internet_gateways => {},
                :tags => {},
                :tag_sets => Hash.new do |tag_set_hash, resource_id|
                  tag_set_hash[resource_id] = {}
                end,
                :subnets => [],
                :vpcs => [],
                :dhcp_options => [],
                :route_tables => [],
                :account_attributes => [
                  {
                    "values"        => ["5"],
                    "attributeName" => "vpc-max-security-groups-per-interface"
                  },
                  {
                    "values"        => ["20"],
                    "attributeName" => "max-instances"
                  },
                  {
                    "values"        => ["EC2", "VPC"],
                    "attributeName" => "supported-platforms"
                  },
                  {
                    "values"        => [VPC_BLANK_VALUE],
                    "attributeName" => "default-vpc"
                  },
                  {
                    "values"        => ["5"],
                    "attributeName" => "max-elastic-ips"
                  },
                  {
                    "values"        => ["5"],
                    "attributeName" => "vpc-max-elastic-ips"
                  }
                ],
                :spot_requests => {},
                :volume_modifications => {}
              }
            end
          end
        end

        def self.reset
          @data = nil
        end

        attr_accessor :region

        def initialize(options={})
          @use_iam_profile = options[:use_iam_profile]
          @aws_credentials_expire_at = Time::now + 20
          setup_credentials(options)
          @region = options[:region] || 'us-east-1'

          if @endpoint = options[:endpoint]
            endpoint = URI.parse(@endpoint)
            @host = endpoint.host or raise InvalidURIError.new("could not parse endpoint: #{@endpoint}")
            @path = endpoint.path
            @port = endpoint.port
            @scheme = endpoint.scheme
          else
            @host = options[:host] || "ec2.#{options[:region]}.amazonaws.com"
            @path       = options[:path]        || '/'
            @persistent = options[:persistent]  || false
            @port       = options[:port]        || 443
            @scheme     = options[:scheme]      || 'https'
          end
          Fog::AWS.validate_region!(@region, @host)
        end

        def region_data
          self.class.data[@region]
        end

        def data
          self.region_data[@aws_access_key_id]
        end

        def reset_data
          self.region_data.delete(@aws_access_key_id)
        end

        def visible_images
          images = self.data[:images].values.reduce({}) do |h, image|
            h.update(image['imageId'] => image)
          end

          self.region_data.each do |aws_access_key_id, data|
            data[:image_launch_permissions].each do |image_id, list|
              if list[:users].include?(self.data[:owner_id])
                images.update(image_id => data[:images][image_id])
              end
            end
          end

          images
        end

        def supported_platforms
          describe_account_attributes.body["accountAttributeSet"].find{ |h| h["attributeName"] == "supported-platforms" }["values"]
        end

        def enable_ec2_classic
          set_supported_platforms(%w[EC2 VPC])
        end

        def disable_ec2_classic
          set_supported_platforms(%w[VPC])
        end

        def set_supported_platforms(values)
          self.data[:account_attributes].find { |h| h["attributeName"] == "supported-platforms" }["values"] = values
        end

        def default_vpc
          vpc_id = describe_account_attributes.body["accountAttributeSet"].find{ |h| h["attributeName"] == "default-vpc" }["values"].first
          vpc_id == VPC_BLANK_VALUE ? nil : vpc_id
        end

        def default_vpc=(value)
          self.data[:account_attributes].find { |h| h["attributeName"] == "default-vpc" }["values"] = [value]
        end

        def setup_default_vpc!
          return if default_vpc.present?

          disable_ec2_classic

          vpc_id = Fog::AWS::Mock.default_vpc_for(region)
          self.default_vpc = vpc_id

          data[:vpcs] << {
            'vpcId' => vpc_id,
            'state' => 'available',
            'cidrBlock' => '172.31.0.0/16',
            'dhcpOptionsId' => Fog::AWS::Mock.dhcp_options_id,
            'tagSet' => {},
            'instanceTenancy' => 'default',
            'enableDnsSupport' => true,
            'enableDnsHostnames' => true,
            'isDefault' => true
          }

          internet_gateway_id = Fog::AWS::Mock.internet_gateway_id
          data[:internet_gateways][internet_gateway_id] = {
            'internetGatewayId' => internet_gateway_id,
            'attachmentSet' => {
              'vpcId' => vpc_id,
              'state' => 'available'
            },
            'tagSet' => {}
          }

          data[:route_tables] << {
            'routeTableId' => Fog::AWS::Mock.route_table_id,
            'vpcId' => vpc_id,
            'routes' => [
              {
                'destinationCidrBlock' => '172.31.0.0/16',
                'gatewayId' => 'local',
                'state' => 'active',
                'origin' => 'CreateRouteTable'
              },
              {
                'destinationCidrBlock' => '0.0.0.0/0',
                'gatewayId' => internet_gateway_id,
                'state' => 'active',
                'origin' => 'CreateRoute'
              }
            ]
          }

          describe_availability_zones.body['availabilityZoneInfo'].map { |z| z['zoneName'] }.each_with_index do |zone, i|
            data[:subnets] << {
              'subnetId'                 => Fog::AWS::Mock.subnet_id,
              'state'                    => 'available',
              'vpcId'                    => vpc_id,
              'cidrBlock'                => "172.31.#{i}.0/16",
              'availableIpAddressCount'  => '251',
              'availabilityZone'         => zone,
              'tagSet'                   => {},
              'mapPublicIpOnLaunch'      => true,
              'defaultForAz'             => true
            }
          end
        end

        def tagged_resources(resources)
          Array(resources).map do |resource_id|
            if match = resource_id.match(/^(\w+)-[a-z0-9]{8,17}/i)
              id = match.captures.first
            else
              raise(Fog::Service::NotFound.new("Unknown resource id #{resource_id}"))
            end

            if MOCKED_TAG_TYPES.has_key? id
              type = MOCKED_TAG_TYPES[id]
            else
              raise(Fog::Service::NotFound.new("Mocking tags of resource #{resource_id} has not been implemented"))
            end

            case type
              when 'image'
                unless visible_images.has_key? resource_id
                 raise(Fog::Service::NotFound.new("Cannot tag #{resource_id}, the image does not exist"))
                end
              when 'vpc'
                if self.data[:vpcs].select {|v| v['vpcId'] == resource_id }.empty?
                  raise(Fog::Service::NotFound.new("Cannot tag #{resource_id}, the vpc does not exist"))
                end
              when 'route_table'
                unless self.data[:route_tables].detect { |r| r['routeTableId'] == resource_id }
                  raise(Fog::Service::NotFound.new("Cannot tag #{resource_id}, the route table does not exist"))
                end
              else
                unless self.data[:"#{type}s"][resource_id]
                 raise(Fog::Service::NotFound.new("Cannot tag #{resource_id}, the #{type} does not exist"))
                end
            end
            { 'resourceId' => resource_id, 'resourceType' => type }
          end
        end


        def apply_tag_filters(resources, filters, resource_id_key)
          tag_set_fetcher = lambda {|resource| self.data[:tag_sets][resource[resource_id_key]] }

          # tag-key: match resources tagged with this key (any value)
          if filters.key?('tag-key')
            value = filters.delete('tag-key')
            resources = resources.select{|r| tag_set_fetcher[r].key?(value)}
          end

          # tag-value: match resources tagged with this value (any key)
          if filters.key?('tag-value')
            value = filters.delete('tag-value')
            resources = resources.select{|r| tag_set_fetcher[r].values.include?(value)}
          end

          # tag:key: match resources tagged with a key-value pair.  Value may be an array, which is OR'd.
          tag_filters = {}
          filters.keys.each do |key|
            tag_filters[key.gsub('tag:', '')] = filters.delete(key) if /^tag:/ =~ key
          end
          for tag_key, tag_value in tag_filters
            resources = resources.select{|r| [tag_value].flatten.include? tag_set_fetcher[r][tag_key]}
          end

          resources
        end

        def setup_credentials(options)
          @aws_access_key_id = options[:aws_access_key_id]
        end
      end

      class Real
        include Fog::AWS::CredentialFetcher::ConnectionMethods
        # Initialize connection to EC2
        #
        # ==== Notes
        # options parameter must include values for :aws_access_key_id and
        # :aws_secret_access_key in order to create a connection
        #
        # ==== Examples
        #   sdb = SimpleDB.new(
        #    :aws_access_key_id => your_aws_access_key_id,
        #    :aws_secret_access_key => your_aws_secret_access_key
        #   )
        #
        # ==== Parameters
        # * options<~Hash> - config arguments for connection.  Defaults to {}.
        #   * region<~String> - optional region to use. For instance,
        #     'eu-west-1', 'us-east-1', and etc.
        #   * aws_session_token<~String> - when using Session Tokens or Federated Users, a session_token must be presented
        #
        # ==== Returns
        # * EC2 object with connection to aws.

        attr_accessor :region

        def initialize(options={})

          @connection_options           = options[:connection_options] || {}
          @region                       = options[:region] ||= 'us-east-1'
          @instrumentor                 = options[:instrumentor]
          @instrumentor_name            = options[:instrumentor_name] || 'fog.aws.compute'
          @version                      = options[:version]     ||  '2016-11-15'
          @retry_request_limit_exceeded = options.fetch(:retry_request_limit_exceeded, true)
          @retry_jitter_magnitude       = options[:retry_jitter_magnitude] || 0.1

          @use_iam_profile = options[:use_iam_profile]
          setup_credentials(options)

          if @endpoint = options[:endpoint]
            endpoint = URI.parse(@endpoint)
            @host = endpoint.host or raise InvalidURIError.new("could not parse endpoint: #{@endpoint}")
            @path = endpoint.path
            @port = endpoint.port
            @scheme = endpoint.scheme
          else
            @host = options[:host] || "ec2.#{options[:region]}.amazonaws.com"
            @path       = options[:path]        || '/'
            @persistent = options[:persistent]  || false
            @port       = options[:port]        || 443
            @scheme     = options[:scheme]      || 'https'
          end

          Fog::AWS.validate_region!(@region, @host)
          @connection = Fog::XML::Connection.new("#{@scheme}://#{@host}:#{@port}#{@path}", @persistent, @connection_options)
        end

        def reload
          @connection.reset
        end

        private
        def setup_credentials(options)
          @aws_access_key_id      = options[:aws_access_key_id]
          @aws_secret_access_key  = options[:aws_secret_access_key]
          @aws_session_token      = options[:aws_session_token]
          @aws_credentials_expire_at = options[:aws_credentials_expire_at]

          @signer = Fog::AWS::SignatureV4.new( @aws_access_key_id, @aws_secret_access_key,@region,'ec2')
        end

        def request(params)
          refresh_credentials_if_expired
          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)

          body, headers = Fog::AWS.signed_params_v4(
             params,
             {'Content-Type' => 'application/x-www-form-urlencoded'},
             {
               :host               => @host,
               :path               => @path,
               :port               => @port,
               :version            => @version,
               :signer             => @signer,
               :aws_session_token  => @aws_session_token,
               :method             => "POST"
            }
          )
          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(body, headers, idempotent, parser)
            end
          else
            _request(body, headers, idempotent, parser)
          end
        end

        def _request(body, headers, idempotent, parser, retries = 0)

          max_retries = 10

          begin
          @connection.request({
              :body       => body,
              :expects    => 200,
              :headers    => headers,
              :idempotent => idempotent,
              :method     => 'POST',
              :parser     => parser
            })
          rescue Excon::Errors::HTTPStatusError => error
            match = Fog::AWS::Errors.match_error(error)
            raise if match.empty?
            raise case match[:code]
                when 'NotFound', 'Unknown'
                  Fog::AWS::Compute::NotFound.slurp(error, match[:message])
                when 'RequestLimitExceeded'                  
                  if @retry_request_limit_exceeded && retries < max_retries
                    jitter = rand * 10 * @retry_jitter_magnitude
                    wait_time = ((2.0 ** (1.0 + retries) * 100) / 1000.0) + jitter
                    Fog::Logger.warning "Waiting #{wait_time} seconds to retry."
                    sleep(wait_time)
                    retries += 1
                    retry
                  elsif @retry_request_limit_exceeded
                    Fog::AWS::Compute::RequestLimitExceeded.slurp(error, "Max retries exceeded (#{max_retries}) #{match[:code]} => #{match[:message]}")
                  else
                    Fog::AWS::Compute::RequestLimitExceeded.slurp(error, "#{match[:code]} => #{match[:message]}")
                  end
                else
                  Fog::AWS::Compute::Error.slurp(error, "#{match[:code]} => #{match[:message]}")
                end
          end
        end
      end
    end
  end

  # @deprecated
  module Compute
    # @deprecated
    class AWS < Fog::AWS::Compute
      # @deprecated
      # @overrides Fog::Service.new (from the fog-core gem)
      def self.new(*)
        Fog::Logger.deprecation 'Fog::Compute::AWS is deprecated, please use Fog::AWS::Compute.'
        super
      end
    end
  end
end
