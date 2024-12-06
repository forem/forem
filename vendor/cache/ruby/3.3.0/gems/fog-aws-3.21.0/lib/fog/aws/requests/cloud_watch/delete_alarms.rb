module Fog
  module AWS
    class CloudWatch
      class Real
        require 'fog/aws/parsers/cloud_watch/delete_alarms'

        # Delete a list of alarms
        # ==== Options
        # * AlarmNames<~Array>: A list of alarms to be deleted
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/index.html?API_DeleteAlarms.html
        #

        def delete_alarms(alarm_names)
          options = {}
          options.merge!(AWS.indexed_param('AlarmNames.member.%d', [*alarm_names]))
          request({
              'Action'    => 'DeleteAlarms',
              :parser     => Fog::Parsers::AWS::CloudWatch::DeleteAlarms.new
            }.merge(options))
        end
      end

      class Mock
        def delete_alarms(alarm_names)
          [*alarm_names].each do |alarm_name|
            unless data[:metric_alarms].key?(alarm_name)
              raise Fog::AWS::AutoScaling::NotFound, "The alarm '#{alarm_name}' does not exist."
            end
          end

          [*alarm_names].each { |alarm_name| data[:metric_alarms].delete(alarm_name) }
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
