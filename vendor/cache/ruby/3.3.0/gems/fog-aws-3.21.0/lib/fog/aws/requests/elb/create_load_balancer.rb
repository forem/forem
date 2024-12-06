module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/create_load_balancer'

        # Create a new Elastic Load Balancer
        #
        # ==== Parameters
        # * availability_zones<~Array> - List of availability zones for the ELB
        # * lb_name<~String> - Name for the new ELB -- must be unique
        # * listeners<~Array> - Array of Hashes describing ELB listeners to assign to the ELB
        #   * 'Protocol'<~String> - Protocol to use. Either HTTP, HTTPS, TCP or SSL.
        #   * 'LoadBalancerPort'<~Integer> - The port that the ELB will listen to for outside traffic
        #   * 'InstancePort'<~Integer> - The port on the instance that the ELB will forward traffic to
        #   * 'InstanceProtocol'<~String> - Protocol for sending traffic to an instance. Either HTTP, HTTPS, TCP or SSL.
        #   * 'SSLCertificateId'<~String> - ARN of the server certificate
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'CreateLoadBalancerResult'<~Hash>:
        #       * 'DNSName'<~String> - DNS name for the newly created ELB
        def create_load_balancer(availability_zones, lb_name, listeners, options = {})
          params = Fog::AWS.indexed_param('AvailabilityZones.member', [*availability_zones])
          params.merge!(Fog::AWS.indexed_param('Subnets.member.%d', options[:subnet_ids]))
          params.merge!(Fog::AWS.serialize_keys('Scheme', options[:scheme]))
          params.merge!(Fog::AWS.indexed_param('SecurityGroups.member.%d', options[:security_groups]))

          listener_protocol = []
          listener_lb_port = []
          listener_instance_port = []
          listener_instance_protocol = []
          listener_ssl_certificate_id = []
          listeners.each do |listener|
            listener_protocol.push(listener['Protocol'])
            listener_lb_port.push(listener['LoadBalancerPort'])
            listener_instance_port.push(listener['InstancePort'])
            listener_instance_protocol.push(listener['InstanceProtocol'])
            listener_ssl_certificate_id.push(listener['SSLCertificateId'])
          end

          params.merge!(Fog::AWS.indexed_param('Listeners.member.%d.Protocol', listener_protocol))
          params.merge!(Fog::AWS.indexed_param('Listeners.member.%d.LoadBalancerPort', listener_lb_port))
          params.merge!(Fog::AWS.indexed_param('Listeners.member.%d.InstancePort', listener_instance_port))
          params.merge!(Fog::AWS.indexed_param('Listeners.member.%d.InstanceProtocol', listener_instance_protocol))
          params.merge!(Fog::AWS.indexed_param('Listeners.member.%d.SSLCertificateId', listener_ssl_certificate_id))

          request({
            'Action'           => 'CreateLoadBalancer',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::CreateLoadBalancer.new
          }.merge!(params))
        end
      end

      class Mock
        def create_load_balancer(availability_zones, lb_name, listeners = [], options = {})
          response = Excon::Response.new
          response.status = 200

          raise Fog::AWS::ELB::IdentifierTaken if self.data[:load_balancers].key? lb_name

          certificate_ids = Fog::AWS::IAM::Mock.data[@aws_access_key_id][:server_certificates].map {|n, c| c['Arn'] }

          listeners = [*listeners].map do |listener|
            if listener['SSLCertificateId'] and !certificate_ids.include? listener['SSLCertificateId']
              raise Fog::AWS::IAM::NotFound.new('CertificateNotFound')
            end
            {'Listener' => listener, 'PolicyNames' => []}
          end

          dns_name = Fog::AWS::ELB::Mock.dns_name(lb_name, @region)

          availability_zones = [*availability_zones].compact
          subnet_ids = options[:subnet_ids] || []
          region = if availability_zones.any?
                     availability_zones.first.gsub(/[a-z]$/, '')
                   elsif subnet_ids.any?
                     # using Hash here for Rubt 1.8.7 support.
                     Hash[
                       Fog::AWS::Compute::Mock.data.select do |_, region_data|
                         region_data[@aws_access_key_id][:subnets].any? do |region_subnets|
                           subnet_ids.include? region_subnets['subnetId']
                         end
                       end
                     ].keys[0]
                   else
                     'us-east-1'
                   end
          supported_platforms = Fog::AWS::Compute::Mock.data[region][@aws_access_key_id][:account_attributes].find { |h| h["attributeName"] == "supported-platforms" }["values"]
          subnets = Fog::AWS::Compute::Mock.data[region][@aws_access_key_id][:subnets].select {|e| subnet_ids.include?(e["subnetId"]) }

          # http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/default-vpc.html
          elb_location = if supported_platforms.include?("EC2")
                           if subnet_ids.empty?
                             'EC2-Classic'
                           else
                             'EC2-VPC'
                           end
                         else
                           if subnet_ids.empty?
                             'EC2-VPC-Default'
                           else
                             'VPC'
                           end
                         end

          security_group = case elb_location
                           when 'EC2-Classic'
                             Fog::AWS::Compute::Mock.data[region][@aws_access_key_id][:security_groups]['amazon-elb-sg']
                           when 'EC2-VPC-Default'
                             compute = Fog::AWS::Compute::new(:aws_access_key_id => @aws_access_key_id, :aws_secret_access_key => @aws_secret_access_key)

                             vpc = compute.vpcs.all.first ||
                               compute.vpcs.create('cidr_block' => '10.0.0.0/24')

                             Fog::AWS::Compute::Mock.data[region][@aws_access_key_id][:security_groups].values.find { |sg|
                               sg['groupName'] =~ /^default_elb/ &&
                                 sg["vpcId"] == vpc.id
                             }
                           when 'EC2-VPC'
                             vpc_id = subnets.first["vpcId"]

                             Fog::AWS::Compute::Mock.data[region][@aws_access_key_id][:security_groups].values.find { |sg|
                               sg['groupName'] == 'default' &&
                                 sg["vpcId"] == vpc_id
                             }
                           end
          self.data[:tags] ||= {}
          self.data[:tags][lb_name] = {}

          self.data[:load_balancers][lb_name] = {
            'AvailabilityZones' => availability_zones,
            'BackendServerDescriptions' => [],
            # Hack to facilitate not updating the local data structure
            # (BackendServerDescriptions) until we do a subsequent
            # describe as that is how AWS behaves.
            'BackendServerDescriptionsRemote' => [],
            'Subnets' => options[:subnet_ids] || [],
            'Scheme' => options[:scheme].nil? ? 'internet-facing' : options[:scheme],
            'SecurityGroups' => options[:security_groups].nil? ? [] : options[:security_groups],
            'CanonicalHostedZoneName' => '',
            'CanonicalHostedZoneNameID' => '',
            'CreatedTime' => Time.now,
            'DNSName' => dns_name,
            'HealthCheck' => {
              'HealthyThreshold' => 10,
              'Timeout' => 5,
              'UnhealthyThreshold' => 2,
              'Interval' => 30,
              'Target' => 'TCP:80'
            },
            'Instances' => [],
            'ListenerDescriptions' => listeners,
            'LoadBalancerAttributes' => {
              'ConnectionDraining' => {'Enabled' => false, 'Timeout' => 300},
              'CrossZoneLoadBalancing' => {'Enabled' => false},
              'ConnectionSettings' => {'IdleTimeout' => 60}
            },
            'LoadBalancerName' => lb_name,
            'Policies' => {
              'AppCookieStickinessPolicies' => [],
              'LBCookieStickinessPolicies' => [],
              'OtherPolicies' => [],
              'Proper' => []
            },
            'SourceSecurityGroup' => {
              'GroupName' => security_group['groupName'],
              'OwnerAlias' => ''
            }
          }
          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'CreateLoadBalancerResult' => {
              'DNSName' => dns_name
            }
          }

          response
        end
      end
    end
  end
end
