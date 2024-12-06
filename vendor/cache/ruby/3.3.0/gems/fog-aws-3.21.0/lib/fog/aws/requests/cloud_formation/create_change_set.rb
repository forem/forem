module Fog
  module AWS
    class CloudFormation
      class Real
        require 'fog/aws/parsers/cloud_formation/create_change_set'

        # Create a Change Set.
        #
        # * stack_name [String] Name of the stack to create.
        # * options [Hash]:
        #   * ChangeSetName [String] The name of the change set.
        #   * Description [String] A description to help you identify this change set.
        #   * TemplateBody [String] Structure containing the template body.
        #   or (one of the two Template parameters is required)
        #   * TemplateURL [String] URL of file containing the template body.
        #   * UsePreviousTemplate [Boolean] Reuse the template that is associated with the stack to create the change set.
        #   * NotificationARNs [Array] List of SNS topics to publish events to.
        #   * Parameters [Hash] Hash of providers to supply to template.
        #   * Capabilities [Array] List of capabilties the stack is granted. Currently CAPABILITY_IAM for allowing the creation of IAM resources.
        #
        # @return [Excon::Response]:
        #   * body [Hash:
        #     * Id [String] - The Amazon Resource Name (ARN) of the change set
        #
        # @see http://docs.amazonwebservices.com/AWSCloudFormation/latest/APIReference/API_CreateChangeSet.html

        def create_change_set(stack_name, options = {})
          params = {
            'StackName' => stack_name,
          }

          if options['ChangeSetName']
            params['ChangeSetName'] = options['ChangeSetName']
          end

          if options['Description']
            params['Description'] = options['Description']
          end
          if options['UsePreviousTemplate']
            params['UsePreviousTemplate'] = options['UsePreviousTemplate']
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

          if options['TemplateBody']
            params['TemplateBody'] = options['TemplateBody']
          elsif options['TemplateURL']
            params['TemplateURL'] = options['TemplateURL']
          end

          if options['Capabilities']
            params.merge!(Fog::AWS.indexed_param("Capabilities.member", [*options['Capabilities']]))
          end

          request({
            'Action'    => 'CreateChangeSet',
            :parser     => Fog::Parsers::AWS::CloudFormation::CreateChangeSet.new
          }.merge!(params))
        end
      end
    end
  end
end
