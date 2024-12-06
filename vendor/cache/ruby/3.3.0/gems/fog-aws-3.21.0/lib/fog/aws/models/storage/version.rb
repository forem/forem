module Fog
  module AWS
    class Storage
      class Version < Fog::Model
        identity  :version,             :aliases => 'VersionId'

        attribute :key,                 :aliases => 'Key'
        attribute :last_modified,       :aliases => ['Last-Modified', 'LastModified']
        attribute :latest,              :aliases => 'IsLatest', :type => :boolean
        attribute :content_length,      :aliases => ['Content-Length', 'Size'], :type => :integer
        attribute :delete_marker,       :type => :boolean

        def file
          @file ||= if collection.file
            collection.file.directory.files.get(key, 'versionId' => version)
          else
            collection.directory.files.get(key, 'versionId' => version)
          end
        end

        def destroy
          if collection.file
            collection.service.delete_object(collection.file.directory.key, key, 'versionId' => version)
          else
            collection.service.delete_object(collection.directory.key, key, 'versionId' => version)
          end
        end
      end
    end
  end
end
