module Fog
  module Parsers
    module AWS
      module RDS
        class DescribeDBParameters < Fog::Parsers::Base
          def reset
            @response = { 'DescribeDBParametersResult' =>{}, 'ResponseMetadata' => {} }
            @parameter = {}
            @parameters = []
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'ParameterValue' then @parameter['ParameterValue'] = value
            when 'DataType' then @parameter['DataType'] = value
            when 'AllowedValues' then @parameter['AllowedValues'] = value
            when 'Source' then @parameter['Source'] = value
            when 'IsModifiable' then
              @parameter['IsModifiable'] =  value == 'true' ? true : false
            when 'Description' then @parameter['Description'] = value
            when 'ApplyType' then @parameter['ApplyType'] = value
            when 'ParameterName' then @parameter['ParameterName'] = value
            when 'Parameter'
              @parameters << @parameter
              @parameter = {}
            when 'Marker'
              @response['DescribeDBParametersResult']['Marker'] = value
            when 'Parameters'
              @response['DescribeDBParametersResult']['Parameters'] = @parameters
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
