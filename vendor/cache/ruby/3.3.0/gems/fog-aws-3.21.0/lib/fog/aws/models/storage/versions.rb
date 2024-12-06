require 'fog/aws/models/storage/version'

module Fog
  module AWS
    class Storage
      class Versions < Fog::Collection
        attribute :file
        attribute :directory

        model Fog::AWS::Storage::Version

        def all(options = {})
          data = if file
            service.get_bucket_object_versions(file.directory.key, options.merge('prefix' => file.key)).body['Versions']
          else
            service.get_bucket_object_versions(directory.key, options).body['Versions']
          end

          load(data)
        end

        def new(attributes = {})
          version_type = attributes.keys.first

          model = super(attributes[version_type])
          model.delete_marker = version_type == 'DeleteMarker'

          model
        end
      end
    end
  end
end
