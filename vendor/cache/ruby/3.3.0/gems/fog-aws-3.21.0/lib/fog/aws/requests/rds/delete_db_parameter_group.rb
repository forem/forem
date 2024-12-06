module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/delete_db_parameter_group'

        # delete a database parameter group
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DeleteDBParameterGroup.html
        # ==== Parameters
        # * DBParameterGroupName <~String> - name of the parameter group. Must not be associated with any instances
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def delete_db_parameter_group(group_name)
          request({
            'Action'  => 'DeleteDBParameterGroup',
            'DBParameterGroupName' => group_name,

            :parser   => Fog::Parsers::AWS::RDS::DeleteDbParameterGroup.new
          })
        end
      end

      class Mock
        def delete_db_parameter_group(group_name)
          response = Excon::Response.new

          if self.data[:parameter_groups].delete(group_name)
            response.status = 200
            response.body = {
              "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            }
            response
          else
            raise Fog::AWS::RDS::NotFound.new("DBParameterGroup not found: #{group_name}")
          end
        end
      end
    end
  end
end
