module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/empty'

        # Create Elastic Load Balancer Listeners
        #
        # ==== Parameters
        # * lb_name<~String> - Name for the new ELB -- must be unique
        # * listeners<~Array> - Array of Hashes describing ELB listeners to add to the ELB
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
        def create_load_balancer_listeners(lb_name, listeners)
          params = {}

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
            'Action'           => 'CreateLoadBalancerListeners',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::Empty.new
          }.merge!(params))
        end
      end

      class Mock
        def create_load_balancer_listeners(lb_name, listeners)
          load_balancer = data[:load_balancers][lb_name]
          raise Fog::AWS::ELB::NotFound unless load_balancer
          response = Excon::Response.new

          certificate_ids = Fog::AWS::IAM::Mock.data[@aws_access_key_id][:server_certificates].map { |_n, c| c['Arn'] }

          listeners.each do |listener|
            if listener['SSLCertificateId'] && !certificate_ids.include?(listener['SSLCertificateId'])
              raise Fog::AWS::IAM::NotFound, 'CertificateNotFound'
            end

            if listener['Protocol'] && listener['InstanceProtocol']
              if (
                  %w[HTTP HTTPS].include?(listener['Protocol']) && !%w[HTTP HTTPS].include?(listener['InstanceProtocol'])
              ) || (
                %w[TCP SSL].include?(listener['Protocol']) && !%w[TCP SSL].include?(listener['InstanceProtocol'])
              )
              raise Fog::AWS::ELB::ValidationError
              end
            end
            load_balancer['ListenerDescriptions'] << { 'Listener' => listener, 'PolicyNames' => [] }
          end

          response.status = 200
          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            }
          }

          response
        end
      end
    end
  end
end
