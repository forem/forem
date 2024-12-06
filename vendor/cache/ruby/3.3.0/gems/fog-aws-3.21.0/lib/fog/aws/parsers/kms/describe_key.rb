module Fog
  module Parsers
    module AWS
      module KMS
        class DescribeKey < Fog::Parsers::Base
          def reset
            @response = { 'KeyMetadata' => {} }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'KeyMetadata'
              @key = {}
            end
          end

          def end_element(name)
            case name
            when 'KeyUsage', 'AWSAccountId', 'Description', 'KeyId', 'Arn'
              @key[name] = value
            when 'CreationDate'
              @key[name] = Time.parse(value)
            when 'Enabled'
              @key[name] = (value == 'true')
            when 'KeyMetadata'
              @response['KeyMetadata'] = @key
            end
          end
        end
      end
    end
  end
end
