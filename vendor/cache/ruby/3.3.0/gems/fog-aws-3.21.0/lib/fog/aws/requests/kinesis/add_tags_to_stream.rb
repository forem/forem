module Fog
  module AWS
    class Kinesis
      class Real
        # Adds or updates tags for the specified Amazon Kinesis stream.
        #
        # ==== Options
        # * StreamName<~String>: The name of the stream.
        # * Tags<~Hash>: The set of key-value pairs to use to create the tags.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_AddTagsToStream.html
        #
        def add_tags_to_stream(options={})
          body = {
            "StreamName" => options.delete("StreamName"),
            "Tags" => options.delete("Tags")
          }.reject{ |_,v| v.nil? }

          request({
                    'X-Amz-Target' => "Kinesis_#{@version}.AddTagsToStream",
                    :body          => body,
                  }.merge(options))
        end
      end

      class Mock
        def add_tags_to_stream(options={})
          stream_name = options.delete("StreamName")
          tags = options.delete("Tags")

          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          stream["Tags"] = stream["Tags"].merge(tags)

          response = Excon::Response.new
          response.status = 200
          response.body = ""
          response
        end
      end
    end
  end
end
