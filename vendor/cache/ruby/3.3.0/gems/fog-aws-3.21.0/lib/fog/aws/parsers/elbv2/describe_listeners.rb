module Fog
  module Parsers
    module AWS
      module ELBV2
        class DescribeListeners < Fog::Parsers::Base
          def reset
            reset_listener
            @default_action = {}
            @certificate = {}
            @config = {}
            @target_groups = []
            @target_group = {}
            @target_group_stickiness_config = {}
            @results = { 'Listeners' => [] }
            @response = { 'DescribeListenersResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_listener
            @listener= { 'DefaultActions' => [], 'Certificates' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'DefaultActions'
              @in_default_actions = true
            when 'Certificates'
              @in_certificates = true
            when 'TargetGroups'
              @in_target_groups = true
            when 'TargetGroupStickinessConfig'
              @in_target_group_stickiness_config = true
            end
          end

          def end_element(name)
            if @in_default_actions
              case name
              when 'member'
                if @in_target_groups
                  @target_groups << @target_group
                  @target_group = {}
                else
                  @listener['DefaultActions'] << @default_action
                  @default_action = {}
                end
              when 'TargetGroupArn'
                if @in_target_groups
                  @target_group[name] = value
                else
                  @default_action[name] = value
                end
              when 'Weight'
                @target_group[name] = value
              when 'Type', 'Order'
                @default_action[name] = value
              when 'Path', 'Protocol', 'Port', 'Query', 'Host', 'StatusCode', 'ContentType',
                   'MessageBody', 'StatusCode'
                @config[name] = value
              when 'RedirectConfig', 'ForwardConfig', 'FixedResponseConfig'
                @default_action[name] = @config
                @config = {}
              when 'DurationSeconds', 'Enabled'
                @target_group_stickiness_config[name] = value
              when 'DefaultActions'
                @in_default_actions = false
              when 'TargetGroupStickinessConfig'
                if @in_target_group_stickiness_config
                  @config['TargetGroupStickinessConfig'] = @target_group_stickiness_config
                  @in_target_group_stickiness_config = false
                  @target_group_stickiness_config = {}
                end
              when 'TargetGroups'
                @config['TargetGroups'] = @target_groups
                @in_target_groups = false
                @target_groups = []
              end
            else
              case name
              when 'member'
                if @in_certificates
                  @listener['Certificates'] << @certificate
                  @certificate = {}
                else
                  @results['Listeners'] << @listener
                  reset_listener
                end
              when 'LoadBalancerArn', 'Protocol', 'Port', 'ListenerArn', 'SslPolicy'
                @listener[name] = value
              when 'CertificateArn'
                @certificate[name] = value
              when 'Certificates'
                @in_certificates = false

              when 'RequestId'
                @response['ResponseMetadata'][name] = value

              when 'NextMarker'
                @results['NextMarker'] = value

              when 'DescribeListenersResponse'
                @response['DescribeListenersResult'] = @results
              end
            end
          end
        end
      end
    end
  end
end
