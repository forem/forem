module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeNetworkInterfaceAttribute < NetworkInterfaceParser
          def reset
            @response             = { }
            @in_description       = false
            @in_group_set         = false
            @in_source_dest_check = false
            @in_attachment        = false
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'description'
              @in_description       = true
            when 'groupSet'
              @in_group_set         = true
              @group                = {}
              unless @response.key?('groupSet')
                @response['groupSet'] = {}
              end
            when 'sourceDestCheck'
              @in_source_dest_check = true
            when 'attachment'
              @in_attachment        = true
              @attachment           = {}
            end
          end

          def end_element(name)
            if @in_description
              case name
              when 'value'
                @response['description'] = value
              when 'description'
                @in_description = false
              end
            elsif @in_group_set
              case name
              when 'item'
                @response['groupSet'][@group['groupId']] = @group['groupName']
                @group = {}
              when 'groupId', 'groupName'
                @group[name] = value
              when 'groupSet'
                @in_group_set = false
              end
            elsif @in_source_dest_check
              case name
              when 'value'
                @response['sourceDestCheck'] = (value == 'true')
              when 'sourceDestCheck'
                @in_source_dest_check = false
              end
            elsif @in_attachment
              case name
              when 'attachmentId', 'instanceId', 'instanceOwnerId', 'deviceIndex', 'status', 'attachTime', 'deleteOnTermination'
                @attachment[name] = value
              when 'attachment'
                @response['attachment'] = @attachment
                @in_attachment          = false
              end
            else
              case name
              when 'requestId', 'networkInterfaceId'
                @response[name] = value
              end
            end
          end
        end
      end
    end
  end
end
