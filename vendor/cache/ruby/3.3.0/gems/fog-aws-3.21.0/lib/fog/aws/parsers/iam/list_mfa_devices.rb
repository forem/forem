module Fog
  module Parsers
    module AWS
      module IAM
        class ListMFADevices < Fog::Parsers::Base
          def reset
            @mfa_device = {}
            @response = { 'MFADevices' => [] }
          end

          def end_element(name)
            case name
            when 'SerialNumber', 'UserName'
              @mfa_device[name] = value
            when 'EnableDate'
              @mfa_device[name] = Time.parse(value)
            when 'member'
              @response['MFADevices'] << @mfa_device
              @mfa_device = {}
            when 'IsTruncated'
              response[name] = (value == 'true')
            when 'Marker', 'RequestId'
              response[name] = value
            end
          end
        end
      end
    end
  end
end
