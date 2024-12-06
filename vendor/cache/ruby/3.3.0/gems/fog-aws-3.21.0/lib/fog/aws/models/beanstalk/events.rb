require 'fog/aws/models/beanstalk/event'

module Fog
  module AWS
    class ElasticBeanstalk
      class Events < Fog::Collection
        model Fog::AWS::ElasticBeanstalk::Event

        def all(options={})
          data = service.describe_events(options).body['DescribeEventsResult']['Events']
          load(data) # data is an array of attribute hashes
        end
      end
    end
  end
end
