module Fog
  module Parsers
    module AWS
      module Storage
        class GetObjectTagging < Fog::Parsers::Base
          def reset
            @in_tag = {}
            @response = {'ObjectTagging' => {}}
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
              @response['ObjectTagging'].merge!(@in_tag)
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
