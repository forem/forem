module Fog
  module Parsers
    module AWS
      module CDN
        class GetInvalidationList < Fog::Parsers::Base
          def reset
            @invalidation_summary = { }
            @response = { 'InvalidationSummary' => [] }
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'InvalidationSummary'
              @response['InvalidationSummary'] << @invalidation_summary
              @invalidation_summary = {}
            when 'Id', 'Status'
              @invalidation_summary[name] = @value
            when 'IsTruncated'
              if @value == 'true'
                @response[name] = true
              else
                @response[name] = false
              end
            when 'Marker', 'NextMarker'
              @response[name] = @value
            when 'MaxItems'
              @response[name] = @value.to_i
            end
          end
        end
      end
    end
  end
end
