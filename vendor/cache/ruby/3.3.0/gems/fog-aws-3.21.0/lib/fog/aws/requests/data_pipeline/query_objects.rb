module Fog
  module AWS
    class DataPipeline
      class Real
        # Queries a pipeline for the names of objects that match a specified set of conditions.
        # http://docs.aws.amazon.com/datapipeline/latest/APIReference/API_QueryObjects.html
        # ==== Parameters
        # * PipelineId <~String> - The ID of the pipeline
        # * Sphere <~String> - Specifies whether the query applies to components or instances.
        #                      Allowable values: COMPONENT, INSTANCE, ATTEMPT.
        # * Marker <~String> - The starting point for the results to be returned.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def query_objects(id, sphere, options={})
          params = {
            'pipelineId' => id,
            'sphere' => sphere,
          }
          params['marker'] = options[:marker] if options[:marker]

          response = request({
            :body => Fog::JSON.encode(params),
            :headers => { 'X-Amz-Target' => 'DataPipeline.QueryObjects' },
          })
        end
      end

      class Mock
        def query_objects(id, sphere, options={})
          response = Excon::Response.new

          find_pipeline(id)

          response.body = {"hasMoreResults" => false, "ids" => ["Default"]}
          response
        end
      end
    end
  end
end
