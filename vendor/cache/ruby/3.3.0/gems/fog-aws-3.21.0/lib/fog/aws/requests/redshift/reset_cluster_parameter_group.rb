module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/update_cluster_parameter_group_parser'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :parameter_group_name - required - (String) The name of the cluster parameter group to be reset.
        # * :reset_all_parameters - (Boolean) If true , all parameters in the specified parameter group will be reset to their default values. Default: true
        # * :parameters - (Array<) An array of names of parameters to be reset. If ResetAllParameters option is not used, then at least one parameter name must be supplied. Constraints: A maximum of 20 parameters can be reset in a single request.
        #   * :parameter_name - (String) The name of the parameter.
        #   * :parameter_value - (String) The value of the parameter.
        #   * :description - (String) A description of the parameter.
        #   * :source - (String) The source of the parameter value, such as "engine-default" or "user".
        #   * :data_type - (String) The data type of the parameter.
        #   * :allowed_values - (String) The valid range of values for the parameter.
        #   * :is_modifiable - (Boolean) If true , the parameter can be modified. Some parameters have security or operational implications that prevent them from being changed.
        #   * :minimum_engine_version - (String) The earliest engine version to which the parameter can apply.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_ResetClusterParameterGroup.html
        def reset_cluster_parameter_group(options = {})
          parameter_group_name = options[:parameter_group_name]
          reset_all_parameters = options[:reset_all_parameters]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::UpdateClusterParameterGroupParser.new
          }

          if options['Parameters']
            options['Parameters'].keys.each_with_index do |name, index|
              params[:query].merge!({
                "Parameters.member.#{index+1}.#{name}"  => options['Parameters'][name]
              })
            end
          end

          params[:query]['Action']             = 'ResetClusterSubnetGroup'
          params[:query]['ParameterGroupName'] = parameter_group_name if parameter_group_name
          params[:query]['ResetAllParameters'] = reset_all_parameters if reset_all_parameters

          request(params)
        end
      end
    end
  end
end
