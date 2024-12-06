module Fog
  module AWS
    class Kinesis
      class Real
        # List availabe streams
        #
        # ==== Options
        # * ExclusiveStartStreamName<~String>: The name of the stream to start the list with.
        # * Limit<~Number>: The maximum number of streams to list.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # https://docs.aws.amazon.com/kinesis/latest/APIReference/API_ListStreams.html
        #
        def list_streams(options={})
          response = request({
                               :idempotent    => true,
                               'X-Amz-Target' => "Kinesis_#{@version}.ListStreams",
                               :body          => {},
                             }.merge(options))
          response.body = Fog::JSON.decode(response.body) unless response.body.nil?
          response
        end
      end

      class Mock
        def list_streams(options={})
          response = Excon::Response.new
          response.status = 200
          response.body =           {
            "HasMoreStreams" => false,
            "StreamNames" => data[:kinesis_streams].map{ |stream| stream["StreamName"] }
          }
          response
        end
      end
    end
  end
end
