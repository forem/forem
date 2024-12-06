module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/update_cluster_parameter_group_parser'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :parameter_group_name - required - (String)
        #    The name of the parameter group to be deleted. Constraints: Must be the name of an
        #    existing cluster parameter group. Cannot delete a default cluster parameter group.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_ModifyClusterParameterGroup.html
        def modify_cluster_parameter_group(options = {})
          parameter_group_name = options[:parameter_group_name]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::UpdateClusterParameterGroupParser.new
          }

          params[:query]['Action']             = 'ModifyClusterParameterGroup'
          params[:query]['ParameterGroupName'] = parameter_group_name if parameter_group_name

          if options['Parameters']
            options['Parameters'].keys.each_with_index do |name, index|
              params[:query].merge!({
                "Parameters.member.#{index+1}.#{name}"  => options['Parameters'][name]
              })
            end
          end

          request(params)
        end
      end
    end
  end
end
