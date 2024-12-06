module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/create_group'

        # Create a new group
        #
        # ==== Parameters
        # * group_name<~String>: name of the group to create (do not include path)
        # * path<~String>: optional path to group, defaults to '/'
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Group'<~Hash>:
        #       * Arn<~String> -
        #       * GroupId<~String> -
        #       * GroupName<~String> -
        #       * Path<~String> -
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_CreateGroup.html
        #
        def create_group(group_name, path = '/')
          request(
            'Action'    => 'CreateGroup',
            'GroupName' => group_name,
            'Path'      => path,
            :parser     => Fog::Parsers::AWS::IAM::CreateGroup.new
          )
        end
      end

      class Mock
        def create_group(group_name, path = '/')
          if data[:groups].key? group_name
            raise Fog::AWS::IAM::EntityAlreadyExists.new("Group with name #{group_name} already exists.")
          else
            data[:groups][group_name][:path] = path
            Excon::Response.new.tap do |response|
              response.body = { 'Group' => {
                                             'GroupId'   => (data[:groups][group_name][:group_id]).strip,
                                             'GroupName' => group_name,
                                             'Path'      => path,
                                             'Arn'       => (data[:groups][group_name][:arn]).strip },
                                'RequestId' => Fog::AWS::Mock.request_id }
              response.status = 200
            end
          end
        end
      end
    end
  end
end
