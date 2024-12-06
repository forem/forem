module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Modify snapshot attributes
        #
        # ==== Parameters
        # * snapshot_id<~String> - Id of snapshot to modify
        # * attributes<~Hash>:
        #   * 'Add.Group'<~Array> - One or more groups to grant volume create permission to
        #   * 'Add.UserId'<~Array> - One or more account ids to grant volume create permission to
        #   * 'Remove.Group'<~Array> - One or more groups to revoke volume create permission from
        #   * 'Remove.UserId'<~Array> - One or more account ids to revoke volume create permission from
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ModifySnapshotAttribute.html]
        #
        def modify_snapshot_attribute(snapshot_id, attributes)
          params = {}
          params.merge!(Fog::AWS.indexed_param('CreateVolumePermission.Add.%d.Group', attributes['Add.Group'] || []))
          params.merge!(Fog::AWS.indexed_param('CreateVolumePermission.Add.%d.UserId', attributes['Add.UserId'] || []))
          params.merge!(Fog::AWS.indexed_param('CreateVolumePermission.Remove.%d.Group', attributes['Remove.Group'] || []))
          params.merge!(Fog::AWS.indexed_param('CreateVolumePermission.Remove.%d.UserId', attributes['Remove.UserId'] || []))
          request({
            'Action'        => 'ModifySnapshotAttribute',
            'SnapshotId'    => snapshot_id,
            :idempotent     => true,
            :parser         => Fog::Parsers::AWS::Compute::Basic.new
          }.merge!(params))
        end
      end
    end
  end
end
