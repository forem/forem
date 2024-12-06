module Fog
  module Parsers
    module AWS
      module ELBV2
        class DescribeTags < Fog::Parsers::Base
          def reset
            @this_key   = nil
            @this_value = nil
            @tags       = Hash.new
            @response   = { 'DescribeTagsResult' => { 'TagDescriptions' => [] }, 'ResponseMetadata' => {} }
            @in_tags = false
          end

          def start_element(name, attrs = [])
            super
            case name
              when 'member'
                unless @in_tags
                  @resource_arn = nil
                  @tags = {}
                end
              when 'Tags'
                @in_tags = true
            end
          end

          def end_element(name)
            super
            case name
              when 'member'
                if @in_tags
                  @tags[@this_key] = @this_value
                  @this_key, @this_value = nil, nil
                else
                  @response['DescribeTagsResult']['TagDescriptions'] << { 'Tags' => @tags, 'ResourceArn' => @resource_arn }
                end
              when 'Key'
                @this_key = value
              when 'Value'
                @this_value = value
              when 'ResourceArn'
                @resource_arn = value
              when 'RequestId'
                @response['ResponseMetadata'][name] = value
              when 'Tags'
                @in_tags = false
            end
          end
        end
      end
    end
  end
end
