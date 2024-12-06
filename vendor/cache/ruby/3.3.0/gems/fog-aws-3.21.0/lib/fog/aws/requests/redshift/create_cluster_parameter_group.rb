module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/create_cluster_parameter_group'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :parameter_group_name - required - (String)
        #    The name of the cluster parameter group. Constraints: Must be 1 to 255 alphanumeric
        #    characters or hyphens First character must be a letter. Cannot end with a hyphen or
        #    contain two consecutive hyphens. Must be unique within your AWS account. This value
        #    is stored as a lower-case string.
        # * :parameter_group_family - required - (String)
        #    The Amazon Redshift engine version to which the cluster parameter group applies. The
        #    cluster engine version determines the set of parameters. To get a list of valid parameter
        #    group family names, you can call DescribeClusterParameterGroups. By default, Amazon
        #    Redshift returns a list of all the parameter groups that are owned by your AWS account,
        #    including the default parameter groups for each Amazon Redshift engine version. The
        #    parameter group family names associated with the default parameter groups provide you
        #    the valid values. For example, a valid family name is "redshift-1.0".
        # * :description - required - (String)
        #    A description of the parameter group.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_CreateClusterParameterGroup.html
        def create_cluster_parameter_group(options = {})
          parameter_group_name   = options[:parameter_group_name]
          parameter_group_family = options[:parameter_group_family]
          description            = options[:description]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::CreateClusterParameterGroup.new
          }

          params[:query]['Action']               = 'CreateClusterParameterGroup'
          params[:query]['ParameterGroupName']   = parameter_group_name if parameter_group_name
          params[:query]['ParameterGroupFamily'] = parameter_group_family if parameter_group_family
          params[:query]['Description']          = description if description

          request(params)
        end
      end
    end
  end
end
