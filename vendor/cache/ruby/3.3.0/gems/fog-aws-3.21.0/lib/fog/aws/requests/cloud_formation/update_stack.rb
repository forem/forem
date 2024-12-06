module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/update_stack'

        # Update a stack.
        #
        # @param [String] stack_name Name of the stack to update.
        # @param [Hash] options
        #   * TemplateBody [String] Structure containing the template body.
        #   or (one of the two Template parameters is required)
        #   * TemplateURL [String] URL of file containing the template body.
        #   * Parameters [Hash] Hash of providers to supply to template.
        #   * Capabilities [Array] List of capabilties the stack is granted. Currently CAPABILITY_IAM for allowing the creation of IAM resources.
        #   * NotificationARNs [Array] List of SNS topics to publish events to.
        #   * ResourceTypes [Array] The template resource types that you have permissions to work.
        #   * StackPolicyBody [String] Structure containing the stack policy body.
        #   * StackPolicyURL [String] URL of file containing the stack policy.
        #   * StackPolicyDuringUpdateBody [String] Structure containing the stack policy body to use during update.
        #   * StackPolicyDuringUpdateURL [String] URL of file containing the stack policy to use during update.
        #   * Tags [Array] Key-value pairs to associate with this stack.
        #   * UsePreviousTemplate [Boolean] Reuse the existing template that is associated with the stack that you are updating.
        #
        # @return [Excon::Response]
        #   * body [Hash]:
        #     * StackId [String] - Id of the stack being updated
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_UpdateStack.html
        #
        def update_stack(stack_name, options = {})
          params = {
            'StackName' => stack_name,
          }

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

          if options['StackPolicyBody']
            params['StackPolicyBody'] = options['StackPolicyBody']
          elsif options['StackPolicyURL']
            params['StackPolicyURL'] = options['StackPolicyURL']
          end

          if options['StackPolicyDuringUpdateBody']
            params['StackPolicyDuringUpdateBody'] = options['StackPolicyDuringUpdateBody']
          elsif options['StackPolicyDuringUpdateURL']
            params['StackPolicyDuringUpdateURL'] = options['StackPolicyDuringUpdateURL']
          end

          num_tags = 0
          if options['Tags']
            options['Tags'].keys.each_with_index do |key, index|
              index += 1 # tags are 1-indexed
              num_tags += 1 # 10 tag max

              params.merge!({
                "Tags.member.#{index}.Key"   => key,
                "Tags.member.#{index}.Value" => options['Tags'][key]
              })
            end
          end

          if num_tags > 10
            raise ArgumentError.new("a maximum of 10 tags can be specified <#{num_tags}>")
          end

          if options['Capabilities']
            params.merge!(Fog::AWS.indexed_param("Capabilities.member", [*options['Capabilities']]))
          end

          if options['NotificationARNs']
            params.merge!(Fog::AWS.indexed_param("NotificationARNs.member", [*options['NotificationARNs']]))
          end

          if options['ResourceTypes']
            params.merge!(Fog::AWS.indexed_param("ResourceTypes.member", [*options['ResourceTypes']]))
          end

          if options['UsePreviousTemplate']
            params['UsePreviousTemplate'] = options['UsePreviousTemplate']
          end

          request({
            'Action'    => 'UpdateStack',
            :parser     => Fog::Parsers::AWS::CloudFormation::UpdateStack.new
          }.merge!(params))
        end
      end
    end
  end
end
