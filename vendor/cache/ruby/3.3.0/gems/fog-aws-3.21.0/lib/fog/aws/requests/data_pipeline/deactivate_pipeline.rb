module Fog
  module AWS
    class DataPipeline
      class Real
        # Activate a pipeline
        # http://docs.aws.amazon.com/datapipeline/latest/APIReference/API_DectivatePipeline.html
        # ==== Parameters
        # * PipelineId <~String> - The ID of the pipeline to activate
        # ' cancelActive <~Boolean> - Indicates whether to cancel any running objects. The default is true, which sets the state of any running objects to CANCELED. If this value is false, the pipeline is deactivated after all running objects finish.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def deactivate_pipeline(id, cancel_active=true)
          params = { 'pipelineId' => id, 'cancelActive' => cancel_active }

          response = request({
            :body => Fog::JSON.encode(params),
            :headers => { 'X-Amz-Target' => 'DataPipeline.DectivatePipeline' }
          })
        end
      end

      class Mock
        def deactivate_pipeline(id, cancel_active=true)
          response = Excon::Response.new

          pipeline = find_pipeline(id)
          pipeline[:active] = false

          response.body = {}
          response
        end
      end
    end
  end
end
