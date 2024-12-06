module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/snapshot_parser'

        class DeleteEventSubscription < Fog::Parsers::AWS::RDS::SnapshotParser
          def reset
            @response = { 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs=[])
            super
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            else
              super
            end
          end
        end
      end
    end
  end
end
