require 'fog/aws/models/beanstalk/application'

module Fog
  module AWS
    class ElasticBeanstalk
      class Applications < Fog::Collection
        model Fog::AWS::ElasticBeanstalk::Application

        def all(application_names=[])
          data = service.describe_applications(application_names).body['DescribeApplicationsResult']['Applications']
          load(data) # data is an array of attribute hashes
        end

        def get(application_name)
          if data = service.describe_applications([application_name]).body['DescribeApplicationsResult']['Applications'].first
            new(data)
          end
        end
      end
    end
  end
end
