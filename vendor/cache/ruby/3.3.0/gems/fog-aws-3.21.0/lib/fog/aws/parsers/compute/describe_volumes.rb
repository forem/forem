module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeVolumes < Fog::Parsers::Base
          def reset
            @attachment = {}
            @in_attachment_set = false
            @response = { 'volumeSet' => [] }
            @tag = {}
            @volume = { 'attachmentSet' => [], 'tagSet' => {} }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'attachmentSet'
              @in_attachment_set = true
            when 'tagSet'
              @in_tag_set = true
            end
          end

          def end_element(name)
            if @in_attachment_set
              case name
              when 'attachmentSet'
                @in_attachment_set = false
              when 'attachTime'
                @attachment[name] = Time.parse(value)
              when 'deleteOnTermination'
                @attachment[name] = value == 'true'
              when 'device', 'instanceId', 'status', 'volumeId', 'kmsKeyId'
                @attachment[name] = value
              when 'item'
                @volume['attachmentSet'] << @attachment
                @attachment = {}
              end
            elsif @in_tag_set
              case name
              when 'key', 'value'
                @tag[name] = value
              when 'item'
                @volume['tagSet'][@tag['key']] = @tag['value']
                @tag = {}
              when 'tagSet'
                @in_tag_set = false
              end
            else
              case name
              when 'availabilityZone', 'snapshotId', 'status', 'volumeId', 'volumeType'
                @volume[name] = value
              when 'createTime'
                @volume[name] = Time.parse(value)
              when 'item'
                @response['volumeSet'] << @volume
                @volume = { 'attachmentSet' => [], 'tagSet' => {} }
              when 'requestId'
                @response[name] = value
              when 'size', 'iops'
                @volume[name] = value.to_i
              when 'encrypted'
                @volume[name] = (value == 'true')
              end
            end
          end
        end
      end
    end
  end
end
