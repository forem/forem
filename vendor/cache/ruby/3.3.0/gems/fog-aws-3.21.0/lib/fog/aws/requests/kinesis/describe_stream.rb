module Fog
  module AWS
    class Kinesis
      class Real
        # Describes the specified stream.
        #
        # ==== Options
        # * ExclusiveStartShardId<~String>: The shard ID of the shard to start with.
        # * Limit<~Number>: The maximum number of shards to return.
        # * StreamName<~String>: The name of the stream to describe.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DescribeStream.html
        #
        def describe_stream(options={})
          body = {
            "ExclusiveStartShardId" => options.delete("ExclusiveStartShardId"),
            "Limit" => options.delete("Limit"),
            "StreamName" => options.delete("StreamName")
          }.reject{ |_,v| v.nil? }

          response = request({
                               :idempotent    => true,
                               'X-Amz-Target' => "Kinesis_#{@version}.DescribeStream",
                               :body          => body,
                             }.merge(options))
          response.body = Fog::JSON.decode(response.body) unless response.body.nil?
          response.body
          response
        end
      end

      class Mock
        def describe_stream(options={})
          stream_name = options.delete("StreamName")

          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          # Strip Records key out of shards for response
          shards = stream["Shards"].reject{ |k,_| k == "Records" }

          response = Excon::Response.new
          response.status = 200
          response.body = { "StreamDescription" => stream.dup.merge("Shards" => shards) }
          response
        end
      end
    end
  end
end
