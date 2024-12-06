module Fog
  module AWS
    class Kinesis
      class Real
        # Merges two adjacent shards in a stream and combines them into a single shard to reduce the stream's capacity to ingest and transport data.
        #
        # ==== Options
        # * AdjacentShardToMerge<~String>: The shard ID of the adjacent shard for the merge.
        # * ShardToMerge<~String>: The shard ID of the shard to combine with the adjacent shard for the merge.
        # * StreamName<~String>: The name of the stream for the merge.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_MergeShards.html
        #
        def merge_shards(options={})
          body = {
            "AdjacentShardToMerge" => options.delete("AdjacentShardToMerge"),
            "ShardToMerge" => options.delete("ShardToMerge"),
            "StreamName" => options.delete("StreamName")
          }.reject{ |_,v| v.nil? }

          request({
                    'X-Amz-Target' => "Kinesis_#{@version}.MergeShards",
                    :body          => body,
                  }.merge(options))
        end
      end

      class Mock
        def merge_shards(options={})
          stream_name = options.delete("StreamName")
          shard_to_merge_id = options.delete("ShardToMerge")
          adjacent_shard_to_merge_id = options.delete("AdjacentShardToMerge")

          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          unless shard_to_merge = stream["Shards"].detect{ |shard| shard["ShardId"] == shard_to_merge_id }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Could not find shard #{shard_to_merge_id} in stream #{stream_name} under account #{@account_id}.")
          end

          unless adjacent_shard_to_merge = stream["Shards"].detect{ |shard| shard["ShardId"] == adjacent_shard_to_merge_id }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Could not find shard #{adjacent_shard_to_merge_id} in stream #{stream_name} under account #{@account_id}.")
          end

          # Close shards (set an EndingSequenceNumber on them)
          shard_to_merge["SequenceNumberRange"]["EndingSequenceNumber"] = next_sequence_number
          adjacent_shard_to_merge["SequenceNumberRange"]["EndingSequenceNumber"] = next_sequence_number

          new_starting_hash_key = [
            shard_to_merge["HashKeyRange"]["StartingHashKey"].to_i,
            adjacent_shard_to_merge["HashKeyRange"]["StartingHashKey"].to_i
          ].min.to_s

          new_ending_hash_key = [
            shard_to_merge["HashKeyRange"]["EndingHashKey"].to_i,
            adjacent_shard_to_merge["HashKeyRange"]["EndingHashKey"].to_i
          ].max.to_s

          # create a new shard with ParentShardId and AdjacentParentShardID
          stream["Shards"] << {
            "HashKeyRange"=> {
              "EndingHashKey" => new_ending_hash_key,
              "StartingHashKey" => new_starting_hash_key
            },
            "SequenceNumberRange" => {
              "StartingSequenceNumber" => next_sequence_number
            },
            "ShardId" => next_shard_id,
            "ParentShardId" => shard_to_merge_id,
            "AdjacentParentShardId" => adjacent_shard_to_merge_id
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
