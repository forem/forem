module Fog
  module AWS
    module Parsers
      module Lambda
        class Base
          def process(body)
            body.inject({}) { |h, (k, v)| h[k] = rules(k, v); h }
          end

          private

          def rules(key, value)
            case value
            when Hash
              process(value)
            when Array
              value.map { |i| process(i) }
            else
              case key
              when 'LastModified'
                Time.parse(value)
              when 'Policy', 'Statement'
                begin
                  Fog::JSON.decode(value)
                rescue Fog::JSON::DecodeError => e
                  Fog::Logger.warning("Error parsing response json - #{e}")
                  {}
                end
              else
                value
              end
            end
          end

        end
      end
    end
  end
end
