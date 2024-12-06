module Fog
  module Parsers
    module AWS
      module SimpleDB
        class Basic < Fog::Parsers::Base
          def initialize(nil_string)
            @nil_string = nil_string
            reset
          end

          def end_element(name)
            case(name)
            when 'BoxUsage'
              response[name] = value.to_f
            when 'RequestId'
              response[name] = value
            end
          end

          def sdb_decode(value)
            value.eql?(@nil_string) ? nil : value
          end
        end
      end
    end
  end
end
