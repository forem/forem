module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeTags < Fog::Parsers::Base
          def reset
            reset_tag
            @results = { 'Tags' => [] }
            @response = { 'DescribeTagsResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_tag
            @tag = {}
          end

          def end_element(name)
            case name
            when 'member'
              @results['Tags'] << @tag
              reset_tag

            when 'Key', 'ResourceId', 'ResourceType', 'Value'
              @tag[name] = value
            when 'PropagateAtLaunch'
              @tag[name] = (value == 'true')

            when 'NextToken'
              @results[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeTagsResponse'
              @response['DescribeTagsResult'] = @results

            end
          end
        end
      end
    end
  end
end
