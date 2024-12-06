module Fog
  module AWS
    class EFS
      class Real
        # Describe all mount targets for a filesystem, or specified mount target
        # http://docs.aws.amazon.com/efs/latest/ug/API_DescribeMountTargets.html
        # ==== Parameters
        # * FileSystemId<~String> - Id of file system to describe mount targets for.  Required unless MountTargetId is specified
        # * MountTargetId<~String> - Specific mount target to describe.  Required if FileSystemId is not specified
        # ==== Returns
        # * response<~Excon::Response>
        #   * body<~Hash>
        def describe_mount_targets(options={})
          params = {}
          if options[:marker]
            params['Marker'] = options[:marker]
          end
          if options[:max_records]
            params['MaxRecords'] = options[:max_records]
          end
          if options[:id]
            params['MountTargetId'] = options[:id]
          end
          if options[:file_system_id]
            params['FileSystemId'] = options[:file_system_id]
          end

          request({
            :path => "mount-targets"
          }.merge(params))
        end
      end

      class Mock
        def describe_mount_targets(options={})
          response = Excon::Response.new

          mount_targets = if id = options[:id]
                            if mount_target = self.data[:mount_targets][id]
                              [mount_target]
                            else
                              raise Fog::AWS::EFS::NotFound.new("Mount target does not exist.")
                            end
                          elsif file_system_id = options[:file_system_id]
                            self.data[:mount_targets].values.select { |mt| mt["FileSystemId"] == file_system_id }
                          else
                            raise Fog::AWS::EFS::Error.new("file system ID or mount target ID must be specified")
                          end

          mount_targets.each do |mount_target|
            mount_target['LifeCycleState'] = 'available'
            self.data[:mount_targets][mount_target["MountTargetId"]] = mount_target
          end

          response.body = {"MountTargets" => mount_targets}
          response
        end
      end
    end
  end
end
