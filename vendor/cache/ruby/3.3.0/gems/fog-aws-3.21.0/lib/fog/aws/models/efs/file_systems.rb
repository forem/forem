require 'fog/aws/models/efs/file_system'

module Fog
  module AWS
    class EFS
      class FileSystems < Fog::Collection
        model Fog::AWS::EFS::FileSystem

        def all
          data = service.describe_file_systems.body["FileSystems"]
          load(data)
        end

        def get(identity)
          data = service.describe_file_systems(:id => identity).body["FileSystems"].first
          new(data)
        rescue Fog::AWS::EFS::NotFound
          nil
        end
      end
    end
  end
end
