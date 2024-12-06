require 'fog/aws/models/data_pipeline/pipeline'

module Fog
  module AWS
    class DataPipeline
      class Pipelines < Fog::Collection
        model Fog::AWS::DataPipeline::Pipeline

        def all
          ids = []

          begin
            result = service.list_pipelines
            ids << result['pipelineIdList'].map { |id| id['id'] }
          end while (result['hasMoreResults'] && result['marker'])

          load(service.describe_pipelines(ids.flatten)['pipelineDescriptionList'])
        end

        def get(id)
          data = service.describe_pipelines([id])['pipelineDescriptionList'].first
          new(data)
        rescue Excon::Errors::BadRequest => error
          data = Fog::JSON.decode(error.response.body)
          raise unless data['__type'] == 'PipelineDeletedException' || data['__type'] == 'PipelineNotFoundException'

          nil
        end
      end
    end
  end
end
