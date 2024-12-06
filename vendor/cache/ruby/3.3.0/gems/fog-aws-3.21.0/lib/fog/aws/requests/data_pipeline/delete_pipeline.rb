module Fog
  module AWS
    class DataPipeline
      class Real
        # Delete a pipeline
        # http://docs.aws.amazon.com/datapipeline/latest/APIReference/API_DeletePipeline.html
        # ==== Parameters
        # * PipelineId <~String> - The id of the pipeline to delete
        # ==== Returns
        # * success<~Boolean> - Whether the delete was successful
        def delete_pipeline(id)
          params = { 'pipelineId' => id }

          response = request({
            :body => Fog::JSON.encode(params),
            :headers => { 'X-Amz-Target' => 'DataPipeline.DeletePipeline' },
          })

          200 == response.status
        end
      end

      class Mock
        def delete_pipeline(id)
          response = Excon::Response.new

          pipeline = find_pipeline(id)
          pipeline[:deleted] = true

          true
        end
      end
    end
  end
end
