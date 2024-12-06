module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/create_db_security_group'

        # creates a db security group
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/index.html?API_CreateDBSecurityGroup.html
        # ==== Parameters
        # * DBSecurityGroupDescription <~String> - The description for the DB Security Group
        # * DBSecurityGroupName <~String> - The name for the DB Security Group. This value is stored as a lowercase string. Must contain no more than 255 alphanumeric characters or hyphens. Must not be "Default".
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def create_db_security_group(name, description = name)
          request({
            'Action'  => 'CreateDBSecurityGroup',
            'DBSecurityGroupName' => name,
            'DBSecurityGroupDescription' => description,
            :parser   => Fog::Parsers::AWS::RDS::CreateDBSecurityGroup.new
          })
        end
      end

      class Mock
        def create_db_security_group(name, description = name)
          response = Excon::Response.new
          if self.data[:security_groups] and self.data[:security_groups][name]
            raise Fog::AWS::RDS::IdentifierTaken.new("DBInstanceAlreadyExists => The security group '#{name}' already exists")
          end

          data = {
            'DBSecurityGroupName' => name,
            'DBSecurityGroupDescription' => description,
            'EC2SecurityGroups' => [],
            'IPRanges' => [],
            'OwnerId' => '0123456789'
          }
          self.data[:security_groups][name] = data
          response.body = {
            "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            'CreateDBSecurityGroupResult' => { 'DBSecurityGroup' => data }
          }
          response
        end
      end
    end
  end
end
