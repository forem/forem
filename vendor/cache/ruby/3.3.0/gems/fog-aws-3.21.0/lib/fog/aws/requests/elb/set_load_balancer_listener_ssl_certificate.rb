module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/empty'

        # Sets the certificate that terminates the specified listener's SSL
        # connections. The specified certificate replaces any prior certificate
        # that was used on the same LoadBalancer and port.
        #
        # ==== Parameters
        # * lb_name<~String> - Name of the ELB
        # * load_balancer_port<~Integer> - The external port of the LoadBalancer
        #   with which this policy has to be associated.
        # * ssl_certificate_id<~String> - ID of the SSL certificate chain to use
        #   example: arn:aws:iam::322191361670:server-certificate/newCert
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        def set_load_balancer_listener_ssl_certificate(lb_name, load_balancer_port, ssl_certificate_id)
          request({
            'Action'           => 'SetLoadBalancerListenerSSLCertificate',
            'LoadBalancerName' => lb_name,
            'LoadBalancerPort' => load_balancer_port,
            'SSLCertificateId' => ssl_certificate_id,
            :parser            => Fog::Parsers::AWS::ELB::Empty.new
          })
        end
      end

      class Mock
        def set_load_balancer_listener_ssl_certificate(lb_name, load_balancer_port, ssl_certificate_id)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]

          certificate_ids = Fog::AWS::IAM::Mock.data[@aws_access_key_id][:server_certificates].map {|n, c| c['Arn'] }
          if !certificate_ids.include? ssl_certificate_id
            raise Fog::AWS::IAM::NotFound.new('CertificateNotFound')
          end

          response = Excon::Response.new

          unless listener = load_balancer['ListenerDescriptions'].find { |listener| listener['Listener']['LoadBalancerPort'] == load_balancer_port }
            response.status = 400
            response.body = "<?xml version=\"1.0\"?><Response><Errors><Error><Code>ListenerNotFound</Code><Message>LoadBalancer does not have a listnener configured at the given port.</Message></Error></Errors><RequestID>#{Fog::AWS::Mock.request_id}</RequestId></Response>"
            raise Excon::Errors.status_error({:expects => 200}, response)
          end

          listener['Listener']['SSLCertificateId'] = ssl_certificate_id

          response.status = 200
          response.body = {
            "ResponseMetadata" => {
              "RequestId" => Fog::AWS::Mock.request_id
            }
          }

          response
        end
      end
    end
  end
end
