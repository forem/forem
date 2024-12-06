module Fog
  module AWS
    class DataPipeline
      class Pipeline < Fog::Model
        identity  :id, :aliases => 'pipelineId'
        attribute :name
        attribute :description
        attribute :tags
        attribute :user_id, :aliases => 'userId'
        attribute :account_id, :aliases => 'accountId'
        attribute :state, :aliases => 'pipelineState'
        attribute :unique_id, :aliases => 'uniqueId'

        def initialize(attributes={})
          # Extract the 'fields' portion of a response to attributes
          if attributes.include?('fields')
            string_fields = attributes['fields'].select { |f| f.include?('stringValue') }
            field_attributes = Hash[string_fields.map { |f| [f['key'][/^@(.+)$/, 1], f['stringValue']] }]
            merge_attributes(field_attributes)
          end

          super
        end

        def save
          requires :name
          requires :unique_id

          data = service.create_pipeline(unique_id, name, nil, tags)
          merge_attributes(data)

          true
        end

        def activate
          requires :id

          service.activate_pipeline(id)

          true
        end

        def put(objects)
          requires :id

          service.put_pipeline_definition(id, objects)

          true
        end

        def destroy
          requires :id

          service.delete_pipeline(id)

          true
        end
      end
    end
  end
end
