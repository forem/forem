module Fog
  module Parsers
    module AWS
      module Compute
        class CreateDhcpOptions < Fog::Parsers::Base
          def reset
            @dhcp_options = { 'dhcpConfigurationSet' => {}, 'tagSet' => {} }
            @response = { 'dhcpOptionsSet' => [] }
            @tag = {}
            @value_set = []
            @dhcp_configuration = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'tagSet'
              @in_tag_set = true
            when 'dhcpConfigurationSet'
              @in_dhcp_configuration_set = true
            when 'valueSet'
              @in_value_set = true
            end
          end

          def end_element(name)
            if @in_tag_set
              case name
                when 'item'
                  @dhcp_options['tagSet'][@tag['key']] = @tag['value']
                  @tag = {}
                when 'key', 'value'
                  @tag[name] = value
                when 'tagSet'
                  @in_tag_set = false
              end
            elsif @in_dhcp_configuration_set
              case name
                when 'item'
                  unless @in_value_set
                    @dhcp_options['dhcpConfigurationSet'][@dhcp_configuration['key']] = @value_set
                    @value_set=[]
                  @dhcp_configuration = {}
                  end
                when 'key', 'value'
                  if !@in_value_set
                    @dhcp_configuration[name] = value
                  else
 			@value_set << value
                  end
                when 'valueSet'
                  @in_value_set = false
                when 'dhcpConfigurationSet'
                  @in_dhcp_configuration_set = false
              end
            else
              case name
              when 'dhcpOptionsId'
                @dhcp_options[name] = value
              when 'dhcpOptions'
                @response['dhcpOptionsSet'] << @dhcp_options
                @dhcp_options = { 'tagSet' => {} }
                @dhcp_options = { 'dhcpOptionsSet' => {} }
              when 'requestId'
                @response[name] = value
              end
            end
          end
        end
      end
    end
  end
end
