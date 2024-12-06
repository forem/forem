module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/get_password_data'

        # Retrieves the encrypted administrator password for an instance running Windows.
        #
        # ==== Parameters
        # * instance_id<~String> - A Windows instance ID
        #
        # ==== Returns
        # # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'instanceId'<~String> - Id of instance
        #     * 'passwordData'<~String> - The encrypted, base64-encoded password of the instance.
        #     * 'requestId'<~String> - Id of request
        #     * 'timestamp'<~Time> - Timestamp of last update to output
        #
        # See http://docs.amazonwebservices.com/AWSEC2/2010-08-31/APIReference/index.html?ApiReference-query-GetPasswordData.html
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-GetPasswordData.html]
        def get_password_data(instance_id)
          request(
            'Action'      => 'GetPasswordData',
            'InstanceId'  => instance_id,
            :idempotent   => true,
            :parser       => Fog::Parsers::AWS::Compute::GetPasswordData.new
          )
        end
      end

      class Mock
        def get_password_data(instance_id)
          response = Excon::Response.new
          if instance = self.data[:instances][instance_id]
            response.status = 200
            response.body = {
              'instanceId'   => instance_id,
              'passwordData' => nil,
              'requestId'    => Fog::AWS::Mock.request_id,
              'timestamp'    => Time.now
            }
            response
          else;
            raise Fog::AWS::Compute::NotFound.new("The instance ID '#{instance_id}' does not exist")
          end
        end
      end
    end
  end
end
