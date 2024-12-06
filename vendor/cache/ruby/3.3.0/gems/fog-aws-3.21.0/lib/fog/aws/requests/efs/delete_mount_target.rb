module Fog
  module AWS
    class EFS
      class Real
        # Delete a mount target
        # http://docs.aws.amazon.com/efs/latest/ug/API_DeleteMountTarget.html
        # ==== Parameters
        # * MountTargetId <~String> - ID of the mount target you want to delete
        # ==== Returns
        # * response<~Excon::Response>
        #   * body - Empty
        #   * status - 204
        def delete_mount_target(id)
          request(
            :path    => "mount-targets/#{id}",
            :method  => "DELETE",
            :expects => 204
          )
        end
      end

      class Mock
        def delete_mount_target(id)
          response = Excon::Response.new

          unless self.data[:mount_targets][id]
            raise Fog::AWS::EFS::NotFound.new("invalid mount target ID: #{id}")
          end

          self.data[:mount_targets].delete(id)

          response.status = 204
          response
        end
      end
    end
  end
end
