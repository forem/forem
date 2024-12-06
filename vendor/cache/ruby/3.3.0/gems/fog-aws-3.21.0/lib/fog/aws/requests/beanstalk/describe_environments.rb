module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/describe_environments'

        # Returns descriptions for existing environments.
        #
        # ==== Options
        # * ApplicationName<~String>: If specified, AWS Elastic Beanstalk restricts the returned descriptions
        #   to include only those that are associated with this application.
        # * EnvironmentIds
        # * EnvironmentNames
        # * IncludeDeleted
        # * IncludedDeletedBackTo
        # * VersionLabel<~String>:
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeEnvironments.html
        #
        def describe_environments(options={})
          if environment_ids = options.delete('EnvironmentIds')
            options.merge!(AWS.indexed_param('EnvironmentIds.member.%d', [*environment_ids]))
          end
          if environment_names = options.delete('EnvironmentNames')
            options.merge!(AWS.indexed_param('EnvironmentNames.member.%d', [*environment_names]))
          end
          request({
                      'Operation'    => 'DescribeEnvironments',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::DescribeEnvironments.new
                  }.merge(options))
        end
      end
    end
  end
end
