module Fog
  module Parsers
    module AWS
      module IAM
        class PolicyVersion < Fog::Parsers::Base
          def reset
            super
            @version = {}
            @response = { 'PolicyVersion' => @version }
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response[name] = value
            when 'VersionId'
              @version[name] = value
            when 'IsDefaultVersion'
              @version[name] = (value == 'true')
            when 'Document'
              @version[name] = if decoded_string = URI.decode_www_form_component(value)
                                 Fog::JSON.decode(decoded_string) rescue value
                               else
                                 value
                               end
            end
            super
          end
        end
      end
    end
  end
end
