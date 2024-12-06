module Fog
  module Parsers
    module AWS
      module Storage
        class GetBucketTagging < Fog::Parsers::Base
          def reset
            @in_tag = {}
            @response = {'BucketTagging' => {}}
          end

          def start_element(name, *args)
            super
            if name == 'Tag'
              @in_tag = {}
            end
          end

          def end_element(name)
            case name
            when 'Tag'
              @response['BucketTagging'].merge!(@in_tag)
              @in_tag = {}
            when 'Key'
              @in_tag[value] = nil
            when 'Value'
              @in_tag = {@in_tag.keys.first => value}
            end
          end
        end
      end
    end
  end
end
