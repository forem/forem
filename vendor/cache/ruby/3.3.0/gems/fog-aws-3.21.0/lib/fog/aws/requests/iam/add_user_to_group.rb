module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Add a user to a group
        #
        # ==== Parameters
        # * group_name<~String>: name of the group
        # * user_name<~String>: name of user to add
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_AddUserToGroup.html
        #
        def add_user_to_group(group_name, user_name)
          request(
            'Action'    => 'AddUserToGroup',
            'GroupName' => group_name,
            'UserName'  => user_name,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def add_user_to_group(group_name, user_name)
          unless data[:groups].key?(group_name)
            raise Fog::AWS::IAM::NotFound.new("The group with name #{group_name} cannot be found.")
          end

          unless data[:users].key?(user_name)
            raise Fog::AWS::IAM::NotFound.new("The user with name #{user_name} cannot be found.")
          end

          unless data[:groups][group_name][:members].include?(user_name)
            data[:groups][group_name][:members] << user_name
          end

          Excon::Response.new.tap do |response|
            response.status = 200
            response.body = { 'RequestId' => Fog::AWS::Mock.request_id }
          end
        end
      end
    end
  end
end
