module Fog
  module AWS
    class Kinesis
      class Real
        # Gets data records from a shard.
        #
        # ==== Options
        # * Limit<~Number>: The maximum number of records to return.
        # * ShardIterator<~String>: The position in the shard from which you want to start sequentially reading data records.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html
        #
        def get_records(options={})
          body = {
            "Limit" => options.delete("Limit"),
            "ShardIterator" => options.delete("ShardIterator")
          }.reject{ |_,v| v.nil? }

          response = request({
                               'X-Amz-Target' => "Kinesis_#{@version}.GetRecords",
                               :body          => body,
                             }.merge(options))
          response.body = Fog::JSON.decode(response.body) unless response.body.nil?
          response
        end
      end

      class Mock
        def get_records(options={})
          shard_iterator = Fog::JSON.decode(options.delete("ShardIterator"))
          limit = options.delete("Limit") || -1
          stream_name = shard_iterator["StreamName"]
          shard_id = shard_iterator["ShardId"]
          starting_sequence_number = (shard_iterator["StartingSequenceNumber"] || 1).to_i

          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          unless shard = stream["Shards"].detect{ |shard| shard["ShardId"] == shard_id }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Could not find shard #{shard_id} in stream #{stream_name} under account #{@account_id}.")
          end

          records = []
          shard["Records"].each do |record|
            next if record["SequenceNumber"].to_i < starting_sequence_number
            records << record
            break if records.size == limit
          end

          shard_iterator["StartingSequenceNumber"] = if records.empty?
            starting_sequence_number.to_s
          else
            (records.last["SequenceNumber"].to_i + 1).to_s
          end

          response = Excon::Response.new
          response.status = 200
          response.body = {
            "MillisBehindLatest"=> 0,
            "NextShardIterator"=> Fog::JSON.encode(shard_iterator),
            "Records"=> records
          }
          response
        end
      end
    end
  end
end
