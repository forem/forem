module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/describe_configuration_settings'

        # Returns a description of the settings for the specified configuration set, that is, either a configuration
        # template or the configuration set associated with a running environment.
        #
        # ==== Options
        # * ApplicationName<~String>: The application for the environment or configuration template.
        # * EnvironmentName<~String>: The name of the environment to describe.
        # * TemplateName<~String>: The name of the configuration template to describe.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeConfigurationSettings.html
        #
        def describe_configuration_settings(options={})
          request({
                      'Operation'    => 'DescribeConfigurationSettings',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::DescribeConfigurationSettings.new
                  }.merge(options))
        end
      end
    end
  end
end
