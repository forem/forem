module Fog
  module AWS
    class DataPipeline
      class Real
        # List all pipelines
        # http://docs.aws.amazon.com/datapipeline/latest/APIReference/API_ListPipelines.html
        # ==== Parameters
        # * Marker <~String> - The starting point for the results to be returned.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def list_pipelines(options={})
          params = {}
          params['Marker'] = options[:marker] if options[:marker]

          response = request({
            :body => Fog::JSON.encode(params),
            :headers => { 'X-Amz-Target' => 'DataPipeline.ListPipelines' },
          })
        end
      end

      class Mock
        def list_pipelines(options={})
          response = Excon::Response.new
          response.body = {"pipelineIdList" => self.data[:pipelines].values.map { |p| {"id" => p["pipelineId"], "name" => p["name"]} } }
          response
        end
      end
    end
  end
end
