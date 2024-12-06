module Fog
  module AWS
    class SimpleDB
      class Real
        # List metadata for SimpleDB domain
        #
        # ==== Parameters
        # * domain_name<~String> - Name of domain. Must be between 3 and 255 of the
        #   following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
        # * item_name<~String> - Name of the item.  May use any UTF-8 characters valid
        #   in xml.  Control characters and sequences not allowed in xml are not
        #   valid.  Can be up to 1024 bytes long.
        # * attributes<~Hash> - Name/value pairs to remove from the item.  Defaults to
        #   nil, which will delete the entire item. Attribute names and values may
        #   use any UTF-8 characters valid in xml. Control characters and sequences
        #   not allowed in xml are not valid.  Each name and value can be up to 1024
        #   bytes long.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'BoxUsage'
        #     * 'RequestId'
        def delete_attributes(domain_name, item_name, attributes = nil)
          request({
            'Action'      => 'DeleteAttributes',
            'DomainName'  => domain_name,
            'ItemName'    => item_name,
            :parser       => Fog::Parsers::AWS::SimpleDB::Basic.new(@nil_string)
          }.merge!(encode_attributes(attributes)))
        end
      end

      class Mock
        def delete_attributes(domain_name, item_name, attributes = nil)
          response = Excon::Response.new
          if self.data[:domains][domain_name]
            if self.data[:domains][domain_name][item_name]
              if attributes
                for key, value in attributes
                  if self.data[:domains][domain_name][item_name][key]
                    if value.nil? || value.empty?
                      self.data[:domains][domain_name][item_name].delete(key)
                    else
                      for v in value
                        self.data[:domains][domain_name][item_name][key].delete(v)
                      end
                    end
                  end
                end
              else
                self.data[:domains][domain_name][item_name].clear
              end
            end
            response.status = 200
            response.body = {
              'BoxUsage'  => Fog::AWS::Mock.box_usage,
              'RequestId' => Fog::AWS::Mock.request_id
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
