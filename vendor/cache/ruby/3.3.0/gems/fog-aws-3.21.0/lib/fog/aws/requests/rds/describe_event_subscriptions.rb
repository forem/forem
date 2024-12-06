module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/describe_event_subscriptions'

        # Describe all or specified event notifications
        # http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_DescribeEventSubscriptions.html
        # === Parameters
        # * Marker <~String> - An optional pagination token provided by a previous DescribeOrderableDBInstanceOptions request
        # * MaxRecords <~String> - The maximum number of records to include in the response (20-100)
        # * SubscriptionName <~String> - The name of the RDS event notification subscription you want to describe
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>
        def describe_event_subscriptions(options={})
          if options[:max_records]
            params['MaxRecords'] = options[:max_records]
          end

          request({
            'Action' => 'DescribeEventSubscriptions',
            :parser  => Fog::Parsers::AWS::RDS::DescribeEventSubscriptions.new
          }.merge(options))
        end
      end

      class Mock
        def describe_event_subscriptions(options={})
          response = Excon::Response.new
          name     = options['SubscriptionName']

          subscriptions = self.data[:event_subscriptions].values
          subscriptions = subscriptions.select { |s| s['CustSubscriptionId'] == name } if name

          non_active = self.data[:event_subscriptions].values.select { |s| s['Status'] != 'active' }

          non_active.each do |s|
            name = s['CustSubscriptionId']
            if s['Status'] == 'creating'
              s['Status'] = 'active'
              self.data[:event_subscriptions][name] = s
            elsif s['Status'] == 'deleting'
              self.data[:event_subscriptions].delete(name)
            end
          end

          if options['SubscriptionName'] && subscriptions.empty?
            raise Fog::AWS::RDS::NotFound.new("Event Subscription #{options['SubscriptionName']} not found.")
          end

          response.body = {
            "ResponseMetadata" => {"RequestId" => Fog::AWS::Mock.request_id},
            "DescribeEventSubscriptionsResult" => {"EventSubscriptionsList" => subscriptions}
          }
          response
        end
      end
    end
  end
end
