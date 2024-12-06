module Fog
  module AWS
    class Kinesis
      class Real
        # Writes a single data record from a producer into an Amazon Kinesis stream.
        #
        # ==== Options
        # * Data<~Blob>: The data blob to put into the record, which is base64-encoded when the blob is serialized.
        # * ExplicitHashKey<~String>: The hash value used to determine explicitly the shard that the data record is assigned to by overriding the partition key hash.
        # * PartitionKey<~String>: Determines which shard in the stream the data record is assigned to.
        # * SequenceNumberForOrdering<~String>: Guarantees strictly increasing sequence numbers, for puts from the same client and to the same partition key.
        # * StreamName<~String>: The stream name associated with the request.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html
        #
        def put_record(options={})
          body = {
            "Data" => options.delete("Data"),
            "ExplicitHashKey" => options.delete("ExplicitHashKey"),
            "PartitionKey" => options.delete("PartitionKey"),
            "SequenceNumberForOrdering" => options.delete("SequenceNumberForOrdering"),
            "StreamName" => options.delete("StreamName")
          }.reject{ |_,v| v.nil? }

          response = request({
                               'X-Amz-Target' => "Kinesis_#{@version}.PutRecord",
                               :body          => body,
                             }.merge(options))
          response.body = Fog::JSON.decode(response.body) unless response.body.nil?
          response
        end
      end

      class Mock
        def put_record(options={})
          stream_name = options.delete("StreamName")

          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          sequence_number = next_sequence_number
          data = options.delete("Data")
          partition_key = options.delete("PartitionKey")

          shard_id = stream["Shards"].sample["ShardId"]
          shard = stream["Shards"].detect{ |shard| shard["ShardId"] == shard_id }
          # store the records on the shard(s)
          shard["Records"] << {
            "SequenceNumber" => sequence_number,
            "Data" => data,
            "PartitionKey" => partition_key
          }

          response = Excon::Response.new
          response.status = 200
          response.body = {
            "SequenceNumber" => sequence_number,
            "ShardId" => shard_id
          }
          response
        end
      end
    end
  end
end
