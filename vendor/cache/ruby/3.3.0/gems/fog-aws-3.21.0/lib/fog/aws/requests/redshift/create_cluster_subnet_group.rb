module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/cluster_subnet_group_parser'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_subnet_group_name - required - (String)
        #    The name for the subnet group. Amazon Redshift stores the value as a lowercase string.
        #    Constraints: Must contain no more than 255 alphanumeric characters or hyphens. Must not
        #    be "Default". Must be unique for all subnet groups that are created by your AWS account.
        #    Example: examplesubnetgroup
        # * :description - required - (String)
        #    A description of the parameter group.
        # * :subnet_ids - required - (Array<)
        #    An array of VPC subnet IDs. A maximum of 20 subnets can be modified in a single request.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_CreateClusterSubnetGroup.html
        def create_cluster_subnet_group(options = {})
          cluster_subnet_group_name = options[:cluster_subnet_group_name]
          description               = options[:description]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::ClusterSubnetGroupParser.new
          }

          if subnet_ids = options.delete(:subnet_ids)
            params[:query].merge!(Fog::AWS.indexed_param('SubnetIds.member.%d', [*subnet_ids]))
          end

          params[:query]['Action']                 = 'CreateClusterSubnetGroup'
          params[:query]['ClusterSubnetGroupName'] = cluster_subnet_group_name if cluster_subnet_group_name
          params[:query]['Description']            = description if description

          request(params)
        end
      end
    end
  end
end
