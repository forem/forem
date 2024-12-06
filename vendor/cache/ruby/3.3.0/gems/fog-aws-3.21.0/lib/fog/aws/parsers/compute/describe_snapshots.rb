module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeSnapshots < Fog::Parsers::Base
          def reset
            @response = { 'snapshotSet' => [] }
            @snapshot = { 'tagSet' => {} }
            @tag = {}
          end

          def start_element(name, attrs = [])
            super
            if name == 'tagSet'
              @in_tag_set = true
            end
          end

          def end_element(name)
            if @in_tag_set
              case name
              when 'item'
                @snapshot['tagSet'][@tag['key']] = @tag['value']
                @tag = {}
              when 'key', 'value'
                @tag[name] = value
              when 'tagSet'
                @in_tag_set = false
              end
            else
              case name
              when 'item'
                @response['snapshotSet'] << @snapshot
                @snapshot = { 'tagSet' => {} }
              when 'description', 'ownerId', 'progress', 'snapshotId', 'status', 'volumeId'
                @snapshot[name] ||= value
              when 'requestId'
                @response[name] = value
              when 'startTime'
                @snapshot[name] = Time.parse(value)
              when 'volumeSize'
                @snapshot[name] = value.to_i
              when 'encrypted'
                @snapshot[name] = (value == 'true')
              end
            end
          end
        end
      end
    end
  end
end
