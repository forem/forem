module Fog
  module Parsers
    module AWS
      module EMR
        class DescribeJobFlows < Fog::Parsers::Base
          def reset
            @context = []
            @contexts = ['BootstrapActions', 'ExecutionStatusDetail', 'Instances', 'Steps', 'InstanceGroups', 'Args']

            @response = { 'JobFlows' => [] }
            @bootstrap_actions = {'ScriptBootstrapActionConfig' => {'Args' => []}}
            @instance = { 'InstanceGroups' => [], 'Placement' => {}}
            @step = {
              'ExecutionStatusDetail' => {},
              'StepConfig' => {
                'HadoopJarStepConfig' =>  {
                  'Args' => [],
                  'Properties' => []
                }
              }
            }
            @flow = {'Instances' => [], 'ExecutionStatusDetail' => {}, 'BootstrapActions' => [], 'Steps' => []}
            @instance_group_detail = {}
            @execution_status_detail = {}
          end

          def start_element(name, attrs = [])
            super
            if @contexts.include?(name)
              @context.push(name)
            end
          end

          def end_element(name)
            if @context.last == 'BootstrapActions'
              case name
              when 'Name'
                @bootstrap_actions[name] = value
              when 'Path'
                @bootstrap_actions['ScriptBootstrapActionConfig'][name] = value
              when 'BootstrapActions'
                @flow['BootstrapActions'] = @bootstrap_actions
                @bootstrap_actions = {'ScriptBootstrapActionConfig' => {'Args' => []}}
              end
            end

            if @context.last == 'ExecutionStatusDetail'
              case name
              when 'CreationDateTime', 'EndDateTime', 'LastStateChangeReason',
                  'ReadyDateTime', 'StartDateTime', 'State'
                @execution_status_detail[name] = value
              when 'ExecutionStatusDetail'
                if @context.include?('Steps')
                  @step['ExecutionStatusDetail'] = @execution_status_detail
                else
                  @flow['ExecutionStatusDetail'] = @execution_status_detail
                end
                @execution_status_detail = {}
              end
            end

            if @context.last == 'Instances'
              case name
              when 'AvailabilityZone'
                @instance['Placement'][name] = value
              when 'Ec2KeyName', 'HadoopVersion', 'InstanceCount', 'KeepJobFlowAliveWhenNoSteps',
                    'MasterInstanceId', 'MasterInstanceType', 'MasterPublicDnsName', 'NormalizedInstanceHours',
                    'SlaveInstanceType', 'TerminationProtected'
                @instance[name] = value
              when 'member'
                @instance['InstanceGroups'] << @instance_group_detail
                @instance_group_detail = {}
              when 'Instances'
                @flow['Instances'] = @instance
                @instance = { 'InstanceGroups' => [], 'Placement' => {}}
              end
            end

            if @context.last == 'InstanceGroups'
              case name
              when 'member'
                @instance['InstanceGroups'] << @instance_group_detail
                @instance_group_detail = {}
              else
                @instance_group_detail[name] = value
              end
            end

            if @context.last == 'Args'
              if name == 'member'
                if @context.include?('Steps')
                  @step['StepConfig']['HadoopJarStepConfig']['Args'] << value.strip
                else
                  @bootstrap_actions['ScriptBootstrapActionConfig']['Args'] << value
                end
              end
            end

            if @context.last == 'Steps'
              case name
              when 'ActionOnFailure', 'Name'
                @step[name] = value
              when 'Jar', 'MainClass'
                @step['StepConfig']['HadoopJarStepConfig'][name] = value
              when 'member'
                @flow['Steps'] << @step
                @step = {
                  'ExecutionStatusDetail' => {},
                  'StepConfig' => {
                    'HadoopJarStepConfig' =>  {
                      'Args' => [],
                      'Properties' => []
                    }
                  }
                }
              end
            end

            if @context.empty?
              case name
              when 'AmiVersion', 'JobFlowId', 'LogUri', 'Name'
                @flow[name] = value
              when 'member'
                @response['JobFlows'] << @flow
                @flow = {'Instances' => [], 'ExecutionStatusDetail' => {}, 'BootstrapActions' => [], 'Steps' => []}
              end
            end

            if @context.last == name
              @context.pop
            end
          end
        end
      end
    end
  end
end
