module Fog
  module AWS
    class Kinesis
      class Real
        # Deletes a stream and all its shards and data.
        #
        # ==== Options
        # * StreamName<~String>: A name to identify the stream.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DeleteStream.html
        #
        def delete_stream(options={})
          body = {
            "StreamName" => options.delete("StreamName")
          }.reject{ |_,v| v.nil? }

          request({
                    'X-Amz-Target' => "Kinesis_#{@version}.DeleteStream",
                    :body          => body,
                  }.merge(options))
        end
      end

      class Mock
        def delete_stream(options={})
          stream_name = options.delete("StreamName")

          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          data[:kinesis_streams].delete(stream)

          response = Excon::Response.new
          response.status = 200
          response.body = ""
          response
        end
      end
    end
  end
end
