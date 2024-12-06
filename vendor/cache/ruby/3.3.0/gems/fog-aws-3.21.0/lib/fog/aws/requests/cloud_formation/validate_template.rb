module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/validate_template'

        # Describe stacks.
        #
        # @param [Hash] options
        # @option options [String] TemplateBody template structure
        # @option options [String] TemplateURL template url
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * Description [String] - description found within the template
        #     * Parameters [String] - list of template parameter structures
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_ValidateTemplate.html
        #
        def validate_template(options = {})
          request({
            'Action'    => 'ValidateTemplate',
            :parser     => Fog::Parsers::AWS::CloudFormation::ValidateTemplate.new
          }.merge!(options))
        end
      end
    end
  end
end
