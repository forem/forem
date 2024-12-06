module Fog
  module Parsers
    module AWS
      module CDN
        class GetStreamingDistributionList < Fog::Parsers::Base
          def reset
            @distribution_summary = { 'CNAME' => [], 'TrustedSigners' => [] }
            @response = { 'StreamingDistributionSummary' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'S3Origin'
              @origin = name
              @distribution_summary[@origin] = {}
            end
          end

          def end_element(name)
            case name
            when 'StreamingDistributionSummary'
              @response['StreamingDistributionSummary'] << @distribution_summary
              @distribution_summary = { 'CNAME' => [], 'TrustedSigners' => [] }
            when 'Comment', 'DomainName', 'Id', 'Status'
              @distribution_summary[name] = @value
            when 'CNAME'
              @distribution_summary[name] << @value
            when 'DNSName', 'OriginAccessIdentity'
              @distribution_summary[@origin][name] = @value
            when 'Enabled'
              if @value == 'true'
                @distribution_summary[name] = true
              else
                @distribution_summary[name] = false
              end
            when 'LastModifiedTime'
              @distribution_summary[name] = Time.parse(@value)
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
