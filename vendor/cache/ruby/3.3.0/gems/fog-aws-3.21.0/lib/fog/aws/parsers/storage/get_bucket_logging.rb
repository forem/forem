module Fog
  module Parsers
    module AWS
      module Storage
        class GetBucketLogging < Fog::Parsers::Base
          def reset
            @grant = { 'Grantee' => {} }
            @response = { 'BucketLoggingStatus' => {} }
          end

          def end_element(name)
            case name
            when 'DisplayName', 'ID'
              if @in_access_control_list
                @grant['Grantee'][name] = value
              else
                @response['Owner'][name] = value
              end
            when 'Grant'
              @response['BucketLoggingStatus']['LoggingEnabled']['TargetGrants'] << @grant
              @grant = { 'Grantee' => {} }
            when 'LoggingEnabled'
              @response['BucketLoggingStatus']['LoggingEnabled'] = { 'TargetGrants' => [] }
            when 'Permission'
              @grant[name] = value
            when 'TargetBucket', 'TargetPrefix'
              @response['BucketLoggingStatus'][name] = value
            when 'URI'
              @grant['Grantee'][name] = value
            end
          end
        end
      end
    end
  end
end
