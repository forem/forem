module Fog
  module AWS
    class Kinesis
      class Real
        # Splits a shard into two new shards in the stream, to increase the stream's capacity to ingest and transport data.
        #
        # ==== Options
        # * NewStartingHashKey<~String>: A hash key value for the starting hash key of one of the child shards created by the split.
        # * ShardToSplit<~String>: The shard ID of the shard to split.
        # * StreamName<~String>: The name of the stream for the shard split.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_SplitShard.html
        #
        def split_shard(options={})
          body = {
            "NewStartingHashKey" => options.delete("NewStartingHashKey"),
            "ShardToSplit" => options.delete("ShardToSplit"),
            "StreamName" => options.delete("StreamName")
          }.reject{ |_,v| v.nil? }

          request({
                    'X-Amz-Target' => "Kinesis_#{@version}.SplitShard",
                    :body          => body,
                  }.merge(options))
        end
      end

      class Mock
        def split_shard(options={})
          stream_name = options.delete("StreamName")
          shard_id = options.delete("ShardToSplit")
          stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }

          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          unless shard = stream["Shards"].detect{ |shard| shard["ShardId"] == shard_id }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Could not find shard #{shard_id} in stream #{stream_name} under account #{@account_id}.")
          end

          # Close original shard (set an EndingSequenceNumber on it)
          shard["SequenceNumberRange"]["EndingSequenceNumber"] = next_sequence_number

          # Calculate new shard ranges
          parent_starting_hash_key = shard["HashKeyRange"]["StartingHashKey"]
          parent_ending_hash_key = shard["HashKeyRange"]["EndingHashKey"]
          new_starting_hash_key = options.delete("NewStartingHashKey")

          # Create two new shards using contiguous hash space based on the original shard
          stream["Shards"] << {
            "HashKeyRange"=> {
              "EndingHashKey" => (new_starting_hash_key.to_i - 1).to_s,
              "StartingHashKey" => parent_starting_hash_key
            },
            "SequenceNumberRange" => {
              "StartingSequenceNumber" => next_sequence_number
            },
            "ShardId" => next_shard_id,
            "ParentShardId" => shard_id
          }
          stream["Shards"] << {
            "HashKeyRange" => {
              "EndingHashKey" => parent_ending_hash_key,
              "StartingHashKey" => new_starting_hash_key
            },
            "SequenceNumberRange" =>{
              "StartingSequenceNumber" => next_sequence_number
            },
            "ShardId" => next_shard_id,
            "ParentShardId" => shard_id
          }

          response = Excon::Response.new
          response.status = 200
          response.body = ""
          response
        end
      end
    end
  end
end
