module Fog
  module Parsers
    module AWS
      module Storage
        class CorsConfiguration < Fog::Parsers::Base
          def reset
            @in_cors_configuration_list = false
            @cors_rule = {}
            @response = { 'CORSConfiguration' => [] }
          end

          def start_element(name, attrs = [])
            super
            if name == 'CORSConfiguration'
              @in_cors_configuration_list = true
            end
          end

          def end_element(name)
            case name
            when 'CORSConfiguration'
              @in_cors_configuration_list = false
            when 'CORSRule'
              @response['CORSConfiguration'] << @cors_rule
              @cors_rule = {}
            when 'MaxAgeSeconds'
              @cors_rule[name] = value.to_i
            when 'ID'
              @cors_rule[name] = value
            when 'AllowedOrigin', 'AllowedMethod', 'AllowedHeader', 'ExposeHeader'
              (@cors_rule[name] ||= []) << value
            end
          end
        end
      end
    end
  end
end
