module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/delete_db_security_group'

        # deletes a db security group
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/index.html?API_DeleteDBSecurityGroup.html
        # ==== Parameters
        # * DBSecurityGroupName <~String> - The name for the DB Security Group to delete
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def delete_db_security_group(name)
          request({
            'Action'  => 'DeleteDBSecurityGroup',
            'DBSecurityGroupName' => name,
            :parser   => Fog::Parsers::AWS::RDS::DeleteDBSecurityGroup.new
          })
        end
      end

      class Mock
        def delete_db_security_group(name, description = name)
          response = Excon::Response.new

          if self.data[:security_groups].delete(name)
            response.status = 200
            response.body = {
              "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            }
            response
          else
            raise Fog::AWS::RDS::NotFound.new("DBSecurityGroupNotFound => #{name} not found")
          end
        end
      end
    end
  end
end
