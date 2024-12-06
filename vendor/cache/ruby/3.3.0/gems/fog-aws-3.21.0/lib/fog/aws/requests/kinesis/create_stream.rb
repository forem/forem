module Fog
  module AWS
    class Kinesis
      class Real
        # Creates a Amazon Kinesis stream.
        #
        # ==== Options
        # * ShardCount<~Number>: The number of shards that the stream will use.
        # * StreamName<~String>: A name to identify the stream.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_CreateStream.html
        #
        def create_stream(options={})
          body = {
            "ShardCount" => options.delete("ShardCount") || 1,
            "StreamName" => options.delete("StreamName")
          }.reject{ |_,v| v.nil? }

          request({
                    'X-Amz-Target' => "Kinesis_#{@version}.CreateStream",
                    :body          => body,
                  }.merge(options))
        end
      end

      class Mock
        def create_stream(options={})
          stream_name = options.delete("StreamName")
          shard_count = options.delete("ShardCount") || 1
          stream_arn = "arn:aws:kinesis:#{@region}:#{@account_id}:stream/#{stream_name}"

          if data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceInUse.new("Stream #{stream_name} under account #{@account_id} already exists.")
          end

          shards = (0...shard_count).map do |shard|
            {
              "HashKeyRange"=>{
                "EndingHashKey"=>"340282366920938463463374607431768211455",
                "StartingHashKey"=>"0"
              },
              "SequenceNumberRange"=>{
                "StartingSequenceNumber"=> next_sequence_number
              },
              "ShardId"=>next_shard_id,
              "Records" => []
            }
          end

          data[:kinesis_streams] = [{
              "HasMoreShards" => false,
              "StreamARN" => stream_arn,
              "StreamName" => stream_name,
              "StreamStatus" => "ACTIVE",
              "Shards" => shards,
              "Tags" => {}
            }]

          response = Excon::Response.new
          response.status = 200
          response.body = ""
          response
        end
      end
    end
  end
end
