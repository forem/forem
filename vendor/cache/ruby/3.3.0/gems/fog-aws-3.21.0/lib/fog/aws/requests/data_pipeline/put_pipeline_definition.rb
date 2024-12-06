module Fog
  module AWS
    class DataPipeline
      module Shared
        class JSONObject
          def initialize(object)
            @json_fields = object.clone
            @id = @json_fields.delete('id')
            @name = @json_fields.delete('name') || @id
          end

          def to_api
            {
              'id' => @id,
              'name' => @name,
              'fields' => fields
            }
          end

          private

          def fields
            @json_fields.map{|k,v| field_for_kv(k,v)}.flatten
          end

          def field_for_kv(key, value)
            if value.is_a?(Hash)
              { 'key' => key, 'refValue' => value['ref'], 'stringValue' => value['stringValue'] }

            elsif value.is_a?(Array)
              value.map { |subvalue| field_for_kv(key, subvalue) }

            else
              { 'key' => key, 'stringValue' => value }

            end
          end
        end

        # Take a list of pipeline object hashes as specified in the Data Pipeline JSON format
        # and transform it into the format expected by the API
        def transform_objects(objects)
          objects.map { |object| JSONObject.new(object).to_api }
        end
      end

      class Real
        include Shared
        # Put raw pipeline definition JSON
        # http://docs.aws.amazon.com/datapipeline/latest/APIReference/API_PutPipelineDefinition.html
        # ==== Parameters
        # * PipelineId <~String> - The ID of the pipeline
        # * PipelineObjects <~String> - Objects in the pipeline
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def put_pipeline_definition(id, pipeline_objects, options={})
          params = {
            'pipelineId' => id,
            'pipelineObjects' => transform_objects(pipeline_objects),
          }.merge(options)

          response = request({
            :body => Fog::JSON.encode(params),
            :headers => { 'X-Amz-Target' => 'DataPipeline.PutPipelineDefinition' },
          })
        end
      end

      class Mock
        include Shared

        def put_pipeline_definition(id, pipeline_objects, _options={})
          response = Excon::Response.new
          options  = _options.dup

          pipeline = find_pipeline(id)

          stringified_objects = if pipeline_objects.any?
                                  transform_objects(stringify_keys(pipeline_objects))
                                else
                                  options.each { |k,v| options[k] = transform_objects(stringify_keys(v)) }
                                end

          if stringified_objects.is_a?(Array)
            stringified_objects = {"pipelineObjects" => stringified_objects}
          end

          self.data[:pipeline_definitions][id] = stringified_objects

          response.body = {"errored" => false, "validationErrors" => [], "validationWarnings" => []}
          response
        end
      end
    end
  end
end
