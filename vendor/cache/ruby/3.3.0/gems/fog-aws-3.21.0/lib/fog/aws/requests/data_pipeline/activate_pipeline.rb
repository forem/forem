module Fog
  module AWS
    class DataPipeline
      class Real
        # Activate a pipeline
        # http://docs.aws.amazon.com/datapipeline/latest/APIReference/API_ActivatePipeline.html
        # ==== Parameters
        # * PipelineId <~String> - The ID of the pipeline to activate
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def activate_pipeline(id)
          params = { 'pipelineId' => id }

          response = request({
            :body => Fog::JSON.encode(params),
            :headers => { 'X-Amz-Target' => 'DataPipeline.ActivatePipeline' }
          })
        end
      end

      class Mock
        def activate_pipeline(id)
          response = Excon::Response.new

          pipeline = find_pipeline(id)
          pipeline[:active] = true

          response.body = {}
          response
        end
      end
    end
  end
end
