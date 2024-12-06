module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/delete_db_subnet_group'

        # Deletes a db subnet group
        # http://docs.aws.amazon.com/AmazonRDS/2013-09-09/APIReference/API_DeleteDBSubnetGroup.html
        # ==== Parameters
        # * DBSubnetGroupName <~String> - The name for the DB Subnet Group. This value is stored as a lowercase string. Must contain no more than 255 alphanumeric characters or hyphens. Must not be "Default".
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def delete_db_subnet_group(name)
          params = { 'Action'  => 'DeleteDBSubnetGroup',
            'DBSubnetGroupName' => name,
            :parser   => Fog::Parsers::AWS::RDS::DeleteDBSubnetGroup.new }
          request(params)
        end
      end

      class Mock
        def delete_db_subnet_group(name)
          response = Excon::Response.new
          unless self.data[:subnet_groups] && self.data[:subnet_groups][name]
            raise Fog::AWS::RDS::NotFound.new("DBSubnetGroupNotFound => The subnet group '#{name}' doesn't exists")
          end

          self.data[:subnet_groups].delete(name)

          response.body = {
            'ResponseMetadata'=>{ 'RequestId'=> Fog::AWS::Mock.request_id },
            'return' => true,
          }
          response
        end
      end
    end
  end
end
