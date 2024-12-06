module Fog
  module AWS
    class Redshift
      class Real
        # ==== Parameters
        #
        # @param [Hash] options
        # * :parameter_group_name - required - (String)
        #    The name of the parameter group to be deleted. Constraints: Must be the name of an
        #    existing cluster parameter group. Cannot delete a default cluster parameter group.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DeleteClusterParameterGroup.html
        def delete_cluster_parameter_group(options = {})
          parameter_group_name = options[:parameter_group_name]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {}
          }

          params[:query]['Action']             = 'DeleteClusterParameterGroup'
          params[:query]['ParameterGroupName'] = parameter_group_name if parameter_group_name

          request(params)
        end
      end
    end
  end
end
