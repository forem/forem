module Fog
  module AWS
    class KMS
      class Real

        require 'fog/aws/parsers/kms/list_keys'

        def list_keys(options={})
          params = {}

          if options[:marker]
            params['Marker'] = options[:marker]
          end

          if options[:limit]
            params['Limit'] = options[:limit]
          end

          request({
            'Action' => 'ListKeys',
            :parser  => Fog::Parsers::AWS::KMS::ListKeys.new
          }.merge(params))
        end
      end

      class Mock
        def list_keys(options={})
          limit  = options[:limit]
          marker = options[:marker]

          if limit
            if limit > 1_000
              raise Fog::AWS::KMS::Error.new(
                "ValidationError => 1 validation error detected: Value '#{limit}' at 'limit' failed to satisfy constraint: Member must have value less than or equal to 1000"
              )
            elsif limit <  1
              raise Fog::AWS::KMS::Error.new(
                "ValidationError => 1 validation error detected: Value '#{limit}' at 'limit' failed to satisfy constraint: Member must have value greater than or equal to 1"
              )
            end
          end

          key_set = if marker
                      self.data[:markers][marker] || []
                    else
                      self.data[:keys].inject([]) { |r,(k,v)|
                        r << { "KeyId" => k, "KeyArn" => v["Arn"] }
                      }
                    end

          keys = if limit
                   key_set.slice!(0, limit)
                 else
                   key_set
                 end

          truncated = keys.size < key_set.size

          marker = truncated && "metadata/l/#{account_id}/#{UUID.uuid}"

          response = Excon::Response.new

          body = {
            'Keys'      => keys,
            'Truncated' => truncated,
            'RequestId' => Fog::AWS::Mock.request_id
          }

          if marker
            self.data[:markers][marker] = key_set
            body.merge!('Marker' => marker)
          end

          response.body = body
          response.status = 200

          response
        end
      end
    end
  end
end
