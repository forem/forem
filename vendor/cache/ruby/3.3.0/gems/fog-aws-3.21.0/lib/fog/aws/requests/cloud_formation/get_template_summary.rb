module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/get_template_summary'

        # Returns information about a new or existing template.
        #
        # * options [Hash]:
        #   * stack_name [String] Name of the stack or the stack ID.
        #   or
        #   * TemplateBody [String] Structure containing the template body.
        #   or
        #   * TemplateURL [String] URL of file containing the template body.
        #
        # @return [Excon::Response]:
        #   * body [Hash:
        #     * Capabilities [Array] List of capabilties in the template.
        #     * CapabilitiesReason [String] The list of resources that generated the values in the Capabilities response element.
        #     * Description [String] Template Description.
        #     * Metadata [String] Template Metadata.
        #     * Parameters [Array] A list of parameter declarations that describe various properties for each parameter.
        #     * ResourceTypes [Array] all the template resource types that are defined in the template
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_GetTemplateSummary.html

        def get_template_summary(options = {})
          params = {}

          if options['StackName']
            params['StackName'] = options['StackName']
          elsif options['TemplateBody']
            params['TemplateBody'] = options['TemplateBody']
          elsif options['TemplateURL']
            params['TemplateURL'] = options['TemplateURL']
          end

          request({
            'Action'    => 'GetTemplateSummary',
            :parser     => Fog::Parsers::AWS::CloudFormation::GetTemplateSummary.new
          }.merge!(params))
        end
      end
    end
  end
end
