module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/copy_snapshot'

        # Copy a snapshot to a different region
        #
        # ==== Parameters
        # * source_snapshot_id<~String> - Id of snapshot
        # * source_region<~String>      - Region to move it from
        # * options<~Hash>:
        #   * 'Description'<~String>    - A description for the EBS snapshot
        #   * 'Encrypted'<~Boolean>     - Specifies whether the destination snapshot should be encrypted
        #   * 'KmsKeyId'<~String>       - The full ARN of the AWS Key Management Service (AWS KMS) CMK
        #                                 to use when creating the snapshot copy.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - id of request
        #     * 'snapshotId'<~String> - id of snapshot
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-CopySnapshot.html]
        def copy_snapshot(source_snapshot_id, source_region, options = {})
          # For backward compatibility. In previous versions third param was a description
          if options.is_a?(String)
            Fog::Logger.warning("copy_snapshot with description as a string in third param is deprecated, use hash instead: copy_snapshot('source-id', 'source-region', { 'Description' => 'some description' })")
            options = { 'Description' => options }
          end
          params              = {
            'Action'           => 'CopySnapshot',
            'SourceSnapshotId' => source_snapshot_id,
            'SourceRegion'     => source_region,
            'Description'      => options['Description'],
            :parser            => Fog::Parsers::AWS::Compute::CopySnapshot.new
          }
          params['Encrypted'] = true if options['Encrypted']
          params['KmsKeyId']  = options['KmsKeyId'] if options['Encrypted'] && options['KmsKeyId']
          request(params)
        end
      end

      class Mock
        #
        # Usage
        #
        # Fog::AWS[:compute].copy_snapshot("snap-1db0a957", 'us-east-1')
        #

        def copy_snapshot(source_snapshot_id, source_region, options = {})
          response = Excon::Response.new
          response.status = 200
          snapshot_id = Fog::AWS::Mock.snapshot_id
          data = {
            'snapshotId'  => snapshot_id,
          }
          self.data[:snapshots][snapshot_id] = data
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id
          }.merge!(data)
          response
        end
      end
    end
  end
end
