module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Delete a group
        #
        # ==== Parameters
        # * group_name<~String>: name of the group to delete
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_DeleteGroup.html
        #
        def delete_group(group_name)
          request(
            'Action'    => 'DeleteGroup',
            'GroupName' => group_name,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def delete_group(group_name)
          if data[:groups].key? group_name
            if data[:groups][group_name][:members].empty?
              data[:groups].delete group_name
              Excon::Response.new.tap do |response|
                response.status = 200
                response.body = { 'RequestId' => Fog::AWS::Mock.request_id }
              end
            else
              raise Fog::AWS::IAM::Error.new("DeleteConflict => Cannot delete entity, must delete users in group first.")
            end
          else
            raise Fog::AWS::IAM::NotFound.new("The group with name #{group_name} cannot be found.")
          end
        end
      end
    end
  end
end
