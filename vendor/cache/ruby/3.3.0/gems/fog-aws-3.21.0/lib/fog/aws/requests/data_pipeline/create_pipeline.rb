module Fog
  module AWS
    class DataPipeline
      class Real
        # Create a pipeline
        # http://docs.aws.amazon.com/datapipeline/latest/APIReference/API_CreatePipeline.html
        # ==== Parameters
        # * UniqueId <~String> - A unique ID for of the pipeline
        # * Name <~String> - The name of the pipeline
        # * Tags <~Hash> - Key/value string pairs to categorize the pipeline
        # * Description <~String> - Description of the pipeline
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def create_pipeline(unique_id, name, description=nil, tags=nil)
          params = {
            'uniqueId' => unique_id,
            'name' => name,
          }
          params['tags'] = tags.map {|k,v| {"key" => k.to_s, "value" => v.to_s}} unless tags.nil? || tags.empty?
          params['Description'] = description if description

          response = request({
            :body => Fog::JSON.encode(params),
            :headers => { 'X-Amz-Target' => 'DataPipeline.CreatePipeline' },
          })
        end
      end

      class Mock
        def create_pipeline(unique_id, name, description=nil, tags=nil)
          response = Excon::Response.new

          if existing_pipeline = self.data[:pipelines][unique_id]
            {"pipelineId" => existing_pipeline["pipelineId"]}
          else
            pipeline_id = Fog::AWS::Mock.data_pipeline_id
            mapped_tags = if tags
                            tags.map { |k,v| {"key" => k.to_s, "value" => v.to_s}}
                          else
                            []
                          end

            pipeline = {
              "name"        => name,
              "description" => description,
              "fields"      => mapped_tags,
              "pipelineId"  => pipeline_id,
            }

            self.data[:pipelines][unique_id] = pipeline

            response.body = {"pipelineId" => pipeline_id}
          end
          response
        end
      end
    end
  end
end
