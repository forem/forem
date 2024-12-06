module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/create_stack'

        # Create a stack.
        #
        # * stack_name [String] Name of the stack to create.
        # * options [Hash]:
        #   * TemplateBody [String] Structure containing the template body.
        #   or (one of the two Template parameters is required)
        #   * TemplateURL [String] URL of file containing the template body.
        #   * DisableRollback [Boolean] Controls rollback on stack creation failure, defaults to false.
        #   * OnFailure [String] Determines what action will be taken if stack creation fails. This must be one of: DO_NOTHING, ROLLBACK, or DELETE.
        #   * NotificationARNs [Array] List of SNS topics to publish events to.
        #   * Parameters [Hash] Hash of providers to supply to template
        #   * TimeoutInMinutes [Integer] Minutes to wait before status is set to CREATE_FAILED
        #   * Capabilities [Array] List of capabilties the stack is granted. Currently CAPABILITY_IAM for allowing the creation of IAM resources
        #   * StackPolicyBody [String] Structure containing the stack policy body.
        #   * StackPolicyURL [String] URL of file containing the stack policy.
        #   * Tags [Array] Key-value pairs to associate with this stack.
        #
        # @return [Excon::Response]:
        #   * body [Hash:
        #     * StackId [String] - Id of the new stack
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_CreateStack.html

        def create_stack(stack_name, options = {})
          params = {
            'StackName' => stack_name,
          }

          if options['DisableRollback']
            params['DisableRollback'] = options['DisableRollback']
          end

          if options['OnFailure']
            params['OnFailure'] = options['OnFailure']
          end

          if options['NotificationARNs']
            params.merge!(Fog::AWS.indexed_param("NotificationARNs.member", [*options['NotificationARNs']]))
          end

          if options['Parameters']
            options['Parameters'].keys.each_with_index do |key, index|
              index += 1 # params are 1-indexed
              params.merge!({
                "Parameters.member.#{index}.ParameterKey"   => key,
                "Parameters.member.#{index}.ParameterValue" => options['Parameters'][key]
              })
            end
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

          if options['TimeoutInMinutes']
            params['TimeoutInMinutes'] = options['TimeoutInMinutes']
          end

          if options['Capabilities']
            params.merge!(Fog::AWS.indexed_param("Capabilities.member", [*options['Capabilities']]))
          end

          request({
            'Action'    => 'CreateStack',
            :parser     => Fog::Parsers::AWS::CloudFormation::CreateStack.new
          }.merge!(params))
        end
      end
    end
  end
end
