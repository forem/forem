module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/estimate_template_cost'

        # Returns the estimated monthly cost of a template.
        #
        # * options [Hash]:
        #   * TemplateBody [String] Structure containing the template body.
        #   or (one of the two Template parameters is required)
        #   * TemplateURL [String] URL of file containing the template body.
        #   * Parameters [Hash] Hash of providers to supply to template
        #
        # @return [Excon::Response]:
        #   * body [Hash:
        #     * Url [String] - An AWS Simple Monthly Calculator URL with a query string that describes the resources required to run the template.
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_EstimateTemplateCost.html

        def estimate_template_cost(options = {})
          params = {}

          if options['Parameters']
            options['Parameters'].keys.each_with_index do |key, index|
              index += 1 # params are 1-indexed
              params.merge!({
                "Parameters.member.#{index}.ParameterKey"   => key,
                "Parameters.member.#{index}.ParameterValue" => options['Parameters'][key]
              })
            end
          end

          if options['TemplateBody']
            params['TemplateBody'] = options['TemplateBody']
          elsif options['TemplateURL']
            params['TemplateURL'] = options['TemplateURL']
          end

          request({
            'Action'    => 'EstimateTemplateCost',
            :parser     => Fog::Parsers::AWS::CloudFormation::EstimateTemplateCost.new
          }.merge!(params))
        end
      end
    end
  end
end
