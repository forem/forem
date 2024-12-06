module Fog
  module AWS
    class ElasticBeanstalk
      class Version < Fog::Model
        attribute :label, :aliases => 'VersionLabel'
        attribute :application_name, :aliases => 'ApplicationName'
        attribute :created_at, :aliases => 'DateCreated'
        attribute :updated_at, :aliases => 'DateUpdated'
        attribute :description, :aliases => 'Description'
        attribute :source_bundle, :aliases => 'SourceBundle'
        attribute :auto_create_application # FIXME - should be write only

        def initialize(attributes={})
          super
        end

        # Return events related to this version
        def events
          requires :label, :application_name
          service.events.all({
                                    'ApplicationName' => application_name,
                                    'VersionLabel' => label
                                })
        end

        # Returns environments running this version
        def environments
          requires :label, :application_name
          service.environments.all({
                                    'ApplicationName' => application_name,
                                    'VersionLabel' => label
                                })
        end

        def destroy(delete_source_bundle = nil)
          requires :label, :application_name
          service.delete_application_version(application_name, label, delete_source_bundle)
          true
        end

        def save
          requires :label, :application_name

          options = {
              'ApplicationName' => application_name,
              'AutoCreateApplication' => auto_create_application,
              'Description' => description,
              'SourceBundle' => source_bundle,
              'VersionLabel' => label
          }
          options.delete_if {|key, value| value.nil?}

          data = service.create_application_version(options).body['CreateApplicationVersionResult']['ApplicationVersion']
          merge_attributes(data)
          true
        end

        # Updates the version label with the current property values.  Currently only updates description
        def update
          requires :label, :application_name

          options = {
              'ApplicationName' => application_name,
              'Description' => description,
              'VersionLabel' => label
          }
          options.delete_if {|key, value| value.nil?}

          data = service.update_application_version(options).body['UpdateApplicationVersionResult']['ApplicationVersion']
          merge_attributes(data)
        end
      end
    end
  end
end
