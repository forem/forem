module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/describe_engine_default_parameters'

        # Returns the default engine and system parameter information for the specified database engine
        # http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DescribeEngineDefaultParameters.html
        #
        # ==== Parameters ====
        # * DBParameterGroupFamily<~String> - The name of the DB parameter group family
        #
        # ==== Returns ====
        # * response<~Excon::Response>:
        #   * body<~Hash>:

        def describe_engine_default_parameters(family, opts={})
          request({
            'Action'                 => 'DescribeEngineDefaultParameters',
            'DBParameterGroupFamily' => family,
            :parser                  => Fog::Parsers::AWS::RDS::DescribeEngineDefaultParameters.new,
          }.merge(opts))
        end
      end

      class Mock
        def describe_engine_default_parameters(family, opts={})
          response = Excon::Response.new

          response.status = 200
          response.body   = {
            "ResponseMetadata"                      => { "RequestId"  => Fog::AWS::Mock.request_id },
            "DescribeEngineDefaultParametersResult" => { "Parameters" => self.data[:default_parameters]}
          }
          response
        end
      end
    end
  end
end
