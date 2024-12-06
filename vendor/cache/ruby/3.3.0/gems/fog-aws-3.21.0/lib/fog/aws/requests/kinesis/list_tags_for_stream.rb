module Fog
  module AWS
    class Kinesis
      class Real
        # Lists the tags for the specified Amazon Kinesis stream.
        #
        # ==== Options
        # * ExclusiveStartTagKey<~String>: The key to use as the starting point for the list of tags.
        # * Limit<~Number>: The number of tags to return.
        # * StreamName<~String>: The name of the stream.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_ListTagsForStream.html
        #
        def list_tags_for_stream(options={})
          body = {
            "ExclusiveStartTagKey" => options.delete("ExclusiveStartTagKey"),
            "Limit" => options.delete("Limit"),
            "StreamName" => options.delete("StreamName")
          }.reject{ |_,v| v.nil? }

          response = request({
                               :idempotent    => true,
                               'X-Amz-Target' => "Kinesis_#{@version}.ListTagsForStream",
                               :body          => body,
                             }.merge(options))
          response.body = Fog::JSON.decode(response.body) unless response.body.nil?
          response.body
          response
        end
      end

      class Mock
        def list_tags_for_stream(options={})
          stream_name = options.delete("StreamName")

          unless stream = data[:kinesis_streams].detect{ |s| s["StreamName"] == stream_name }
            raise Fog::AWS::Kinesis::ResourceNotFound.new("Stream #{stream_name} under account #{@account_id} not found.")
          end

          response = Excon::Response.new
          response.status = 200
          response.body = {
            "HasMoreTags" => false,
            "Tags" => stream["Tags"].map{ |k,v|
              {"Key" => k, "Value" => v}
            }

          }
          response
        end
      end
    end
  end
end
