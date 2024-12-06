module Fog
  module AWS
    class EFS
      class Real
        # Describe mount target security groups
        # http://docs.aws.amazon.com/efs/latest/ug/API_DescribeMountTargetSecurityGroups.html
        # ==== Parameters
        # * MountTargetId - Id of the mount target for which you want to describe security groups
        # ==== Returns
        # * response<~Excon::Response>
        # * body<~Hash>

        def describe_mount_target_security_groups(mount_target_id)
          request(
            :path => "mount-targets/#{mount_target_id}/security-groups"
          )
        end
      end

      class Mock
        def describe_mount_target_security_groups(mount_target_id)
          response = Excon::Response.new

          unless self.data[:mount_targets][mount_target_id]
            raise Fog::AWS::EFS::NotFound.new("invalid mount target ID: #{mount_target_id}")
          end

          response.body = {"SecurityGroups" => self.data[:security_groups][mount_target_id]}
          response
        end
      end
    end
  end
end
