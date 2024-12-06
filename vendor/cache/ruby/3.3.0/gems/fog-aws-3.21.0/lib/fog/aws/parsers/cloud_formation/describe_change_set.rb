module Fog
  module Parsers
    module AWS
      module CloudFormation
        class DescribeChangeSet < Fog::Parsers::Base
          def reset
            @response = fresh_change_set
            reset_parameter
            reset_change
            reset_resource_change
            reset_resource_change_detail
            reset_resource_target_definition
          end

          def reset_parameter
            @parameter = {}
          end

          def reset_change
            @change = {}
          end

          def reset_resource_change
            @resource_change = {'Details' => [], 'Scope' => [] }
          end

          def reset_resource_change_detail
            @resource_change_detail = {}
          end

          def reset_resource_target_definition
            @resource_target_definition = {}
          end

          def fresh_change_set
            {'Capabilities' => [], 'Changes' => [], 'NotificationARNs' => [], 'Parameters' => [], 'Tags' => []}
          end

          def start_element(name, attrs=[])
            super
            case name
            when 'Capabilities'
              @in_capabilities = true
            when 'Changes'
              @in_changes = true
            when 'ResourceChange'
              @in_resource_change = true
            when 'Scope'
              @in_scope = true
            when 'Details'
              @in_details = true
            when 'Target'
              @in_target = true
            when 'NotificationARNs'
              @in_notification_arns = true
            when 'Parameters'
              @in_parameters = true
            when 'Tags'
              @in_tags = true
            end
          end

          def end_element(name)
            case name
            when 'ChangeSetId', 'ChangeSetName', 'Description', 'ExecutionStatus', 'StackId', 'StackName', 'StatusReason', 'Status'
              @response[name] = value
            when 'CreationTime'
              @response[name] = Time.parse(value)
            when 'member'
              if @in_capabilities
                @response['Capabilities'] << value
              elsif @in_scope
                @resource_change['Scope'] << value
              elsif @in_notification_arns
                @response['NotificationARNs'] << value
              elsif @in_parameters
                @response['Parameters'] << @parameter
                reset_parameter
              elsif @in_tags
                @response['Tags'] << @tag
                reset_tag
              elsif @in_details
                @resource_change['Details'] << @resource_change_detail
                reset_resource_change_detail
              elsif @in_changes
                @response['Changes'] << @change
                reset_change
              end
            when 'ParameterValue', 'ParameterKey'
              @parameter[name] = value if @in_parameters
            when 'Parameters'
              @in_parameters = false
            when 'Value', 'Key'
              @tag[name] = value if @in_tags
            when 'Tags'
              @in_tags = false
            when 'Capabilities'
              @in_capabilities = false
            when 'Scope'
              @in_scope = false
            when 'NotificationARNs'
              @in_notification_arns = false
            when 'Type'
              @change[name] = value if @in_changes
            when 'Changes'
              @in_changes = false
            when 'ResourceChange'
              if @in_resource_change
                @change[name] = @resource_change
                @in_resource_change = false
              end
            when 'Action','LogicalResourceId','PhysicalResourceId','Replacement','ResourceType'
              @resource_change[name] = value  if @in_resource_change
            when 'Details'
              @in_details = false
            when 'CausingEntity','ChangeSource','Evaluation'
              if @in_details
                @resource_change_detail[name] = value
              end
            when 'Attribute','Name','RequiresRecreation'
              if @in_target
                @resource_target_definition[name] = value
              end
            when 'Target'
              if @in_target
                @resource_change_detail[name] = @resource_target_definition
                @in_target = false
              end
            end
          end
        end
      end
    end
  end
end