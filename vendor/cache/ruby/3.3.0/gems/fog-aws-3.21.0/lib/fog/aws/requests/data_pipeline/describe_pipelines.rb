module Fog
  module AWS
    class DataPipeline
      class Real
        # Describe pipelines
        # http://docs.aws.amazon.com/datapipeline/latest/APIReference/API_DescribePipelines.html
        # ==== Parameters
        # * PipelineIds <~String> - ID of pipeline to retrieve information for
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def describe_pipelines(ids)
          params = {}
          params['pipelineIds'] = ids

          response = request({
            :body => Fog::JSON.encode(params),
            :headers => { 'X-Amz-Target' => 'DataPipeline.DescribePipelines' },
          })
        end
      end

      class Mock
        def describe_pipelines(ids)
          response = Excon::Response.new
          response.body = {"pipelineDescriptionList" => self.data[:pipelines].values.select { |p| !p[:deleted] && ids.include?(p["pipelineId"]) } }
          response
        end
      end
    end
  end
end
