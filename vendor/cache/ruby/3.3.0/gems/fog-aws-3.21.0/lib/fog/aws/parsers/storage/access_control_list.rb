module Fog
  module Parsers
    module AWS
      module Storage
        class AccessControlList < Fog::Parsers::Base
          def reset
            @in_access_control_list = false
            @grant = { 'Grantee' => {} }
            @response = { 'Owner' => {}, 'AccessControlList' => [] }
          end

          def start_element(name, attrs = [])
            super
            if name == 'AccessControlList'
              @in_access_control_list = true
            end
          end

          def end_element(name)
            case name
            when 'AccessControlList'
              @in_access_control_list = false
            when 'Grant'
              @response['AccessControlList'] << @grant
              @grant = { 'Grantee' => {} }
            when 'DisplayName', 'ID'
              if @in_access_control_list
                @grant['Grantee'][name] = value
              else
                @response['Owner'][name] = value
              end
            when 'Permission'
              @grant[name] = value
            when 'URI'
              @grant['Grantee'][name] = value
            end
          end
        end
      end
    end
  end
end
