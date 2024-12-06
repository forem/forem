module Fog
  module AWS
    class SimpleDB
      class Real
        require 'fog/aws/parsers/simpledb/domain_metadata'

        # List metadata for SimpleDB domain
        #
        # ==== Parameters
        # * domain_name<~String> - Name of domain. Must be between 3 and 255 of the
        # following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'AttributeNameCount' - number of unique attribute names in domain
        #     * 'AttributeNamesSizeBytes' - total size of unique attribute names, in bytes
        #     * 'AttributeValueCount' - number of all name/value pairs in domain
        #     * 'AttributeValuesSizeBytes' - total size of attributes, in bytes
        #     * 'BoxUsage'
        #     * 'ItemCount' - number of items in domain
        #     * 'ItemNameSizeBytes' - total size of item names in domain, in bytes
        #     * 'RequestId'
        #     * 'Timestamp' - last update time for metadata.
        def domain_metadata(domain_name)
          request(
            'Action'      => 'DomainMetadata',
            'DomainName'  => domain_name,
            :idempotent   => true,
            :parser       => Fog::Parsers::AWS::SimpleDB::DomainMetadata.new(@nil_string)
          )
        end
      end

      class Mock
        def domain_metadata(domain_name)
          response = Excon::Response.new
          if domain = self.data[:domains][domain_name]
            response.status = 200

            attribute_names = []
            attribute_values = []
            for item in domain.values
              for key, values in item
                attribute_names << key
                for value in values
                  attribute_values << value
                end
              end
            end

            response.body = {
              'AttributeNameCount'        => attribute_names.length,
              'AttributeNamesSizeBytes'   => attribute_names.join('').length,
              'AttributeValueCount'       => attribute_values.length,
              'AttributeValuesSizeBytes'  => attribute_values.join('').length,
              'BoxUsage'                  => Fog::AWS::Mock.box_usage,
              'ItemCount'                 => domain.keys.length,
              'ItemNamesSizeBytes'        => domain.keys.join('').length,
              'RequestId'                 => Fog::AWS::Mock.request_id,
              'Timestamp'                 => Time.now
            }
          else
            response.status = 400
            raise(Excon::Errors.status_error({:expects => 200}, response))
          end
          response
        end
      end
    end
  end
end
