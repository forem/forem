module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/create_dhcp_options'

        # Creates a set of DHCP options for your VPC
        #
        # ==== Parameters
        # * DhcpConfigurationOptions<~Hash> - hash of key value dhcp options to assign
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CreateDhcpOptions.html]
        def create_dhcp_options(dhcp_configurations = {})
          params = {}
          params.merge!(indexed_multidimensional_params(dhcp_configurations))
          request({
            'Action'    => 'CreateDhcpOptions',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::CreateDhcpOptions.new
          }.merge!(params))
        end
        private
          def indexed_multidimensional_params(multi_params)
            params = {}
            multi_params.keys.each_with_index do |key, key_index|
              key_index += 1
              params[format('DhcpConfiguration.%d.Key', key_index)] = key
              [*multi_params[key]].each_with_index do |value, value_index|
                value_index += 1
                params[format('DhcpConfiguration.%d.Value.%d', key_index, value_index)] = value
              end
            end
            params
         end
       end
      class Mock
        def create_dhcp_options(dhcp_configurations = {})
          params = {}
          params.merge!(indexed_multidimensional_params(dhcp_configurations))
          Excon::Response.new.tap do |response|
            response.status = 200
            self.data[:dhcp_options].push({
              'dhcpOptionsId' => Fog::AWS::Mock.dhcp_options_id,
              'dhcpConfigurationSet'  => {},
              'tagSet'             => {}
            })
            response.body = {
              'requestId'    => Fog::AWS::Mock.request_id,
              'dhcpOptionsSet'      => self.data[:dhcp_options]
            }
          end
        end
        private
          def indexed_multidimensional_params(multi_params)
            params = {}
            multi_params.keys.each_with_index do |key, key_index|
              key_index += 1
              params[format('DhcpConfiguration.%d.Key', key_index)] = key
              [*multi_params[key]].each_with_index do |value, value_index|
                value_index += 1
                params[format('DhcpConfiguration.%d.Value.%d', key_index, value_index)] = value
              end
            end
            params
         end
      end
    end
  end
end
