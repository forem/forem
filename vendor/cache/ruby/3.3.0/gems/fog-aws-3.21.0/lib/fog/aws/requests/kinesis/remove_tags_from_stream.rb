module Fog
  module AWS
    class Kinesis
      class Real
        # Deletes tags from the specified Amazon Kinesis stream.
        #
        # ==== Options
        # * StreamName<~String>: The name of the stream.
        # * TagKeys<~Array>: A list of tag keys.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_RemoveTagsFromStream.html
        #
        def remove_tags_from_stream(options={})
          body = {
            "StreamName" => options.delete("StreamName"),
            "TagKeys" => options.delete("TagKeys")
          }.reject{ |_,v| v.nil? }

          request({
                    'X-Amz-Target' => "Kinesis_#{@version}.RemoveTagsFromStream",
                    :body          => body,
                  }.merge(options))
        end
      end

      class Mock
        def remove_tags_from_stream(options={})
          stream_name = options.delete("StreamName")
          tags = options.delete("TagKeys")

          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          stream["Tags"] = stream["Tags"].delete_if { |k,_| tags.include?(k) }

          response = Excon::Response.new
          response.status = 200
          response.body = ""
          response
        end
      end

    end
  end
end
