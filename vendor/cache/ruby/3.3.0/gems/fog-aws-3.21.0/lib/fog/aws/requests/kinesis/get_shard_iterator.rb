module Fog
  module AWS
    class Kinesis
      class Real
        # Gets a shard iterator.
        #
        # ==== Options
        # * ShardId<~String>: The shard ID of the shard to get the iterator for.
        # * ShardIteratorType<~String>: Determines how the shard iterator is used to start reading data records from the shard.
        # * StartingSequenceNumber<~String>: The sequence number of the data record in the shard from which to start reading from.
        # * StreamName<~String>: A name to identify the stream.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html
        #
        def get_shard_iterator(options={})
          body = {
            "ShardId" => options.delete("ShardId"),
            "ShardIteratorType" => options.delete("ShardIteratorType"),
            "StartingSequenceNumber" => options.delete("StartingSequenceNumber"),
            "StreamName" => options.delete("StreamName")
          }.reject{ |_,v| v.nil? }

          response = request({
                               'X-Amz-Target' => "Kinesis_#{@version}.GetShardIterator",
                               :body          => body,
                             }.merge(options))
          response.body = Fog::JSON.decode(response.body) unless response.body.nil?
          response
        end
      end

      class Mock
        def get_shard_iterator(options={})
          stream_name = options["StreamName"]

          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          response = Excon::Response.new
          response.status = 200
          response.body = {
            "ShardIterator" => Fog::JSON.encode(options) # just encode the options that were given, we decode them in get_records
          }
          response
        end
      end
    end
  end
end
