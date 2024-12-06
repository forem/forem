module Fog
  module AWS
    class Kinesis
      class Real
        # Writes multiple data records from a producer into an Amazon Kinesis stream in a single call (also referred to as a PutRecords request).
        #
        # ==== Options
        # * Records<~Array>: The records associated with the request.
        #   * Record<~Hash>: A record.
        #     * Data<~Blob>: The data blob to put into the record, which is base64-encoded when the blob is serialized.
        #     * ExplicitHashKey<~String>: The hash value used to determine explicitly the shard that the data record is assigned to by overriding the partition key hash.
        #     * PartitionKey<~String>: Determines which shard in the stream the data record is assigned to.
        # * StreamName<~String>: The stream name associated with the request.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html
        #
        def put_records(options={})
          body = {
            "Records" => options.delete("Records"),
            "StreamName" => options.delete("StreamName")
          }.reject{ |_,v| v.nil? }

          response = request({
                               'X-Amz-Target' => "Kinesis_#{@version}.PutRecords",
                               :body          => body,
                             }.merge(options))
          response.body = Fog::JSON.decode(response.body) unless response.body.nil?
          response
        end
      end

      class Mock
        def put_records(options={})
          stream_name = options.delete("StreamName")
          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          records = options.delete("Records")
          record_results = records.map { |r|
            sequence_number = next_sequence_number

            shard_id = stream["Shards"].sample["ShardId"]
            shard = stream["Shards"].detect{ |shard| shard["ShardId"] == shard_id }
            # store the records on the shard(s)
            shard["Records"] << r.merge("SequenceNumber" => sequence_number)
            {
              "SequenceNumber" => sequence_number,
              "ShardId" => shard_id
            }
          }

          response = Excon::Response.new
          response.status = 200
          response.body = {
            "FailedRecordCount" => 0,
            "Records" => record_results
          }
          response
        end
      end
    end
  end
end
