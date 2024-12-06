module Fog
  module AWS
    class SimpleDB
      class Real
        require 'fog/aws/parsers/simpledb/get_attributes'

        # List metadata for SimpleDB domain
        #
        # ==== Parameters
        # * domain_name<~String> - Name of domain. Must be between 3 and 255 of the
        #   following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
        # * item_name<~String> - Name of the item.  May use any UTF-8 characters valid
        #   in xml.  Control characters and sequences not allowed in xml are not
        #   valid.  Can be up to 1024 bytes long.
        # * options<~Hash>:
        #   * AttributeName<~Array> - Attributes to return from the item.  Defaults to
        #     {}, which will return all attributes. Attribute names and values may use
        #     any UTF-8 characters valid in xml. Control characters and sequences not
        #     allowed in xml are not valid.  Each name and value can be up to 1024
        #     bytes long.
        #    * ConsistentRead<~Boolean> - When set to true, ensures most recent data is returned. Defaults to false.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Attributes' - list of attribute name/values for the item
        #     * 'BoxUsage'
        #     * 'RequestId'
        def get_attributes(domain_name, item_name, options = {})
          if options.is_a?(Array)
            Fog::Logger.deprecation("get_attributes with array attributes param is deprecated, use 'AttributeName' => attributes) instead [light_black](#{caller.first})[/]")
            options = {'AttributeName' => options}
          end
          options['AttributeName'] ||= []
          request({
            'Action'          => 'GetAttributes',
            'ConsistentRead'  => !!options['ConsistentRead'],
            'DomainName'      => domain_name,
            'ItemName'        => item_name,
            :idempotent       => true,
            :parser           => Fog::Parsers::AWS::SimpleDB::GetAttributes.new(@nil_string)
          }.merge!(encode_attribute_names(options['AttributeName'])))
        end
      end

      class Mock
        def get_attributes(domain_name, item_name, options = {})
          if options.is_a?(Array)
            Fog::Logger.deprecation("get_attributes with array attributes param is deprecated, use 'AttributeName' => attributes) instead [light_black](#{caller.first})[/]")
            options['AttributeName'] ||= options if options.is_a?(Array)
          end
          options['AttributeName'] ||= []
          response = Excon::Response.new
          if self.data[:domains][domain_name]
            object = {}
            if !options['AttributeName'].empty?
              for attribute in options['AttributeName']
                if self.data[:domains][domain_name].key?(item_name) && self.data[:domains][domain_name][item_name].key?(attribute)
                  object[attribute] = self.data[:domains][domain_name][item_name][attribute]
                end
              end
            elsif self.data[:domains][domain_name][item_name]
              object = self.data[:domains][domain_name][item_name]
            end
            response.status = 200
            response.body = {
              'Attributes'  => object,
              'BoxUsage'    => Fog::AWS::Mock.box_usage,
              'RequestId'   => Fog::AWS::Mock.request_id
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
