module Fog
  module Parsers
    module AWS
      module CDN

        class StreamingDistribution < Fog::Parsers::Base
          def reset
            @response = { 'StreamingDistributionConfig' => { 'CNAME' => [], 'Logging' => {}, 'TrustedSigners' => [] } }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'CustomOrigin', 'S3Origin'
              @origin = name
              @response['StreamingDistributionConfig'][@origin] = {}
            end
          end

          def end_element(name)
            case name
            when 'AwsAccountNumber'
              @response['StreamingDistributionConfig']['TrustedSigners'] << @value
            when 'Bucket', 'Prefix'
              @response['StreamingDistributionConfig']['Logging'][name] = @value
            when 'CNAME'
              @response['StreamingDistributionConfig']['CNAME'] << @value
            when 'DNSName', 'OriginAccessIdentity', 'OriginProtocolPolicy'
              @response['StreamingDistributionConfig'][@origin][name] = @value
            when 'DomainName', 'Id', 'Status'
              @response[name] = @value
            when 'CallerReference', 'Comment', 'DefaultRootObject', 'Origin', 'OriginAccessIdentity'
              @response['StreamingDistributionConfig'][name] = @value
            when 'Enabled'
              if @value == 'true'
                @response['StreamingDistributionConfig'][name] = true
              else
                @response['StreamingDistributionConfig'][name] = false
              end
            when 'HTTPPort', 'HTTPSPort'
              @response['StreamingDistributionConfig'][@origin][name] = @value.to_i
            when 'InProgressInvalidationBatches'
              @response[name] = @value.to_i
            when 'LastModifiedTime'
              @response[name] = Time.parse(@value)
            when 'Protocol'
              @response['StreamingDistributionConfig']['RequireProtocols'] = @value
            when 'Self'
              @response['StreamingDistributionConfig']['TrustedSigners'] << 'Self'
            end
          end
        end
      end
    end
  end
end
