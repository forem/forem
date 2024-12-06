module Fog
  module Parsers
    module AWS
      module Elasticache
        require 'fog/aws/parsers/elasticache/base'

        class CacheClusterParser < Base
          def reset
            super
            reset_cache_cluster
          end

          def reset_cache_cluster
            @cache_cluster = {
              'CacheSecurityGroups' => [],
              'CacheNodes' => [],
              'CacheParameterGroup' => {},
              'ConfigurationEndpoint' => {},
              'SecurityGroups' => []
            }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'CacheSecurityGroup'; then @cache_security_group = {}
            when 'CacheNode'; then @cache_node = {}
            when 'PendingModifiedValues'; then @pending_values = {}
            when 'ConfigurationEndpoint'; then @configuration_endpoint = {} 
            when 'SecurityGroups'
              @in_security_groups = true
              @security_group_members = []
            when 'member'
              if @in_security_groups
                @in_security_group_member = true
                @security_group_member = {}
              end
            end
          end

          def end_element(name)
            case name
            when 'AutoMinorVersionUpgrade', 'CacheClusterId',
              'CacheClusterStatus', 'CacheNodeType', 'Engine',
              'PreferredAvailabilityZone', 'PreferredMaintenanceWindow'
              @cache_cluster[name] = value
            when 'EngineVersion', 'CacheNodeIdsToRemoves'
              if @pending_values
                @pending_values[name] = value ? value.strip : name
              else
                @cache_cluster[name] = value
              end
            when 'NumCacheNodes'
              if @pending_values
                @pending_values[name] = value.to_i
              else
                @cache_cluster[name] = value.to_i
              end
            when 'CacheClusterCreateTime'
              @cache_cluster[name] = DateTime.parse(value)
            when 'CacheSecurityGroup'
              @cache_cluster["#{name}s"] << @cache_security_group unless @cache_security_group.empty?
            when 'ConfigurationEndpoint'
              @cache_cluster['ConfigurationEndpoint'] = @configuration_endpoint
            when 'CacheSecurityGroupName', 'CacheSubnetGroupName'
              @cache_cluster[name] = value
            when 'Status'
              if @in_security_group_member
                @security_group_member[name] = value
              else
                @cache_cluster[name] = value
              end
            when 'CacheNode'
              @cache_cluster["#{name}s"] << @cache_node unless @cache_node.empty?
              @cache_node = nil
            when'PendingModifiedValues'
              @cache_cluster[name] = @pending_values
              @pending_values = nil
            when 'Port', 'Address'
              if @cache_node
                @cache_node[name] = value ? value.strip : name                
              elsif @pending_values
                @pending_values[name] = value ? value.strip : name
              elsif @configuration_endpoint
                @configuration_endpoint[name] = value ? value.strip : name
              end
            when 'CacheNodeCreateTime', 'CacheNodeStatus',
              'ParameterGroupStatus', 'CacheNodeId'
              if @cache_node
                @cache_node[name] = value ? value.strip : name
              elsif @pending_values
                @pending_values[name] = value ? value.strip : name
              end
            when 'CacheNodeIdsToReboots', 'CacheParameterGroupName', 'ParameterApplyStatus'
              @cache_cluster['CacheParameterGroup'][name] = value
            when 'SecurityGroups'
              @in_security_groups = false
              @cache_cluster['SecurityGroups'] = @security_group_members
            when 'SecurityGroupId'
              @security_group_member[name] = value if @in_security_group_member
            when 'member'
              if @in_security_groups
                @in_security_group_member = false
                @security_group_members << @security_group_member
              end
            else
              super
            end
          end
        end
      end
    end
  end
end
