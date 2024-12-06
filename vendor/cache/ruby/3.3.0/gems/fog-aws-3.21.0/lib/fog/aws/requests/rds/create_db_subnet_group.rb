module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/create_db_subnet_group'

        # Creates a db subnet group
        # http://docs.amazonwebservices.com/AmazonRDS/2012-01-15/APIReference/API_CreateDBSubnetGroup.html
        # ==== Parameters
        # * DBSubnetGroupName <~String> - The name for the DB Subnet Group. This value is stored as a lowercase string. Must contain no more than 255 alphanumeric characters or hyphens. Must not be "Default".
        # * SubnetIds <~Array> - The EC2 Subnet IDs for the DB Subnet Group.
        # * DBSubnetGroupDescription <~String> - The description for the DB Subnet Group
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def create_db_subnet_group(name, subnet_ids, description = name)
          params = { 'Action'  => 'CreateDBSubnetGroup',
            'DBSubnetGroupName' => name,
            'DBSubnetGroupDescription' => description,
            :parser   => Fog::Parsers::AWS::RDS::CreateDBSubnetGroup.new }
          params.merge!(Fog::AWS.indexed_param("SubnetIds.member", Array(subnet_ids)))
          request(params)
        end
      end

      class Mock
        def create_db_subnet_group(name, subnet_ids, description = name)
          response = Excon::Response.new
          if self.data[:subnet_groups] && self.data[:subnet_groups][name]
            raise Fog::AWS::RDS::IdentifierTaken.new("DBSubnetGroupAlreadyExists => The subnet group '#{name}' already exists")
          end

          # collection = Fog::AWS::Compute.new(:aws_access_key_id => 'mock key', :aws_secret_access_key => 'mock secret')
          compute_data = Fog::AWS::Compute::Mock.data[self.region][self.aws_access_key_id]

          subnets = subnet_ids.map do |snid|
            subnet = compute_data[:subnets].detect { |s| s['subnetId'] == snid }
            raise Fog::AWS::RDS::NotFound.new("InvalidSubnet => The subnet '#{snid}' was not found") if subnet.nil?
            subnet
          end
          vpc_id = subnets.first['vpcId']

          data = {
            'DBSubnetGroupName' => name,
            'DBSubnetGroupDescription' => description,
            'SubnetGroupStatus' => 'Complete',
            'Subnets' => subnet_ids,
            'VpcId' => vpc_id
          }
          self.data[:subnet_groups][name] = data
          response.body = {
            "ResponseMetadata"=>{ "RequestId"=> Fog::AWS::Mock.request_id },
            'CreateDBSubnetGroupResult' => { 'DBSubnetGroup' => data }
          }
          response
        end
      end
    end
  end
end
