module Fog
  module AWS
    class SimpleDB
      class Real
        # Create a SimpleDB domain
        #
        # ==== Parameters
        # * domain_name<~String>:: Name of domain. Must be between 3 and 255 of the
        # following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'BoxUsage'
        #     * 'RequestId'
        def create_domain(domain_name)
          request(
            'Action'      => 'CreateDomain',
            'DomainName'  => domain_name,
            :idempotent   => true,
            :parser       => Fog::Parsers::AWS::SimpleDB::Basic.new(@nil_string)
          )
        end
      end

      class Mock
        def create_domain(domain_name)
          response = Excon::Response.new
          self.data[:domains][domain_name] = {}
          response.status = 200
          response.body = {
            'BoxUsage'  => Fog::AWS::Mock.box_usage,
            'RequestId' => Fog::AWS::Mock.request_id
          }
          response
        end
      end
    end
  end
end
