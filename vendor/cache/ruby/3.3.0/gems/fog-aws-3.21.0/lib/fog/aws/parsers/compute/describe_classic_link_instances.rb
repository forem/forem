module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeClassicLinkInstances < Fog::Parsers::Base
          def reset
            @instance = { 'tagSet' => {}, 'groups' => [] }
            @response = { 'instancesSet' => [] }
            @tag = {}
            @group = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'groupSet'
              @in_group_set = true
            when 'tagSet'
              @in_tag_set = true
            end
          end

          def end_element(name)
            if @in_tag_set
              case name
              when 'item'
                @instance['tagSet'][@tag['key']] = @tag['value']
                @tag = {}
              when 'key', 'value'
                @tag[name] = value
              when 'tagSet'
                @in_tag_set = false
              end
            elsif @in_group_set
              case name
              when 'item'
                @instance['groups'] << @group
                @group = {}
              when 'groupId', 'groupName'
                @group[name] = value
              when 'groupSet'
                @in_group_set = false
              end
            else
              case name
              when 'vpcId', 'instanceId'
                @instance[name] = value
              when 'item'
                @response['instancesSet'] << @instance
                @instance = { 'tagSet' => {}, 'groups' => [] }
              when 'requestId', 'nextToken'
                @response[name] = value
              end
            end
          end
        end
      end
    end
  end
end
