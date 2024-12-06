module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/update_group'

        # Update a Group
        #
        # ==== Parameters
        # * group_name<~String> - Required. Name of the Group to update. If you're changing the name of the Group, this is the original Group name.
        # * options<~Hash>:
        #   * new_path<~String> - New path for the Group. Include this parameter only if you're changing the Group's path.
        #   * new_group_name<~String> - New name for the Group. Include this parameter only if you're changing the Group's name.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #     * 'Group'<~Hash> - Changed Group info
        #       * 'Arn'<~String> -
        #       * 'Path'<~String> -
        #       * 'GroupId'<~String> -
        #       * 'GroupName'<~String> -
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/index.html?API_UpdateGroup.html
        #
        def update_group(group_name, options = {})
          request({
            'Action'    => 'UpdateGroup',
            'GroupName' => group_name,
            :parser     => Fog::Parsers::AWS::IAM::UpdateGroup.new
          }.merge!(options))
        end
      end

      class Mock
        def update_group(group_name, options = {})
          raise Fog::AWS::IAM::NotFound.new(
            "The user with name #{group_name} cannot be found."
          ) unless self.data[:groups].key?(group_name)

          response = Excon::Response.new

          group = self.data[:groups][group_name]

          new_path       = options['NewPath']
          new_group_name = options['NewGroupName']

          if new_path
            unless new_path.match(/\A\/[a-zA-Z0-9]+\/\Z/)
              raise Fog::AWS::IAM::ValidationError,
                "The specified value for path is invalid. It must begin and end with / and contain only alphanumeric characters and/or / characters."
            end

            group[:path] = new_path
          end

          if new_group_name
            self.data[:groups].delete(group_name)
            self.data[:groups][new_group_name] = group
          end

          response.status = 200
          response.body = {
            'Group'     => {},
            'RequestId' => Fog::AWS::Mock.request_id
          }

          response
        end
      end
    end
  end
end
