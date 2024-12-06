module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Delete a instance_profile
        #
        # ==== Parameters
        # * instance_profile_name<~String>: name of the instance_profile to delete
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteInstanceProfile.html
        #
        def delete_instance_profile(instance_profile_name)
          request(
            'Action'    => 'DeleteInstanceProfile',
            'InstanceProfileName'  => instance_profile_name,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def delete_instance_profile(instance_profile_name)
          response = Excon::Response.new

          unless profile = self.data[:instance_profiles][instance_profile_name]
            raise Fog::AWS::IAM::NotFound.new("Instance Profile #{instance_profile_name} cannot be found.")
          end

          self.data[:instance_profiles].delete(instance_profile_name)

          response.body = {"RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
