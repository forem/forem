require 'fog/aws/models/beanstalk/environment'

module Fog
  module AWS
    class ElasticBeanstalk
      class Environments < Fog::Collection
        model Fog::AWS::ElasticBeanstalk::Environment

        def all(options={})
          data = service.describe_environments(options).body['DescribeEnvironmentsResult']['Environments']
          load(data) # data is an array of attribute hashes
        end

        # Gets an environment given a name.
        #
        def get(environment_name)
          options = { 'EnvironmentNames' => [environment_name] }

          if data = service.describe_environments(options).body['DescribeEnvironmentsResult']['Environments'].first
            new(data)
          end
        end
      end
    end
  end
end
