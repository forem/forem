module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeVpcClassicLink < Fog::Parsers::Base
          def reset
            @vpc = { 'tagSet' => {} }
            @response = { 'vpcSet' => [] }
            @tag = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'tagSet'
              @in_tag_set = true
            end
          end

          def end_element(name)
            if @in_tag_set
              case name
                when 'item'
                  @vpc['tagSet'][@tag['key']] = @tag['value']
                  @tag = {}
                when 'key', 'value'
                  @tag[name] = value
                when 'tagSet'
                  @in_tag_set = false
              end
            else
              case name
              when 'vpcId'
                @vpc[name] = value
              when 'classicLinkEnabled'
                @vpc[name] = value == 'true'
              when 'item'
                @response['vpcSet'] << @vpc
                @vpc = { 'tagSet' => {} }
              when 'requestId'
                @response[name] = value
              end
            end
          end
        end
      end
    end
  end
end
