module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/describe_configuration_options'

        # Describes the configuration options that are used in a particular configuration template or environment,
        # or that a specified solution stack defines. The description includes the values the options,
        # their default values, and an indication of the required action on a running environment
        # if an option value is changed.
        #
        # ==== Options
        # * ApplicationName<~String>: The name of the application associated with the configuration template or
        #   environment. Only needed if you want to describe the configuration options associated with either the
        #   configuration template or environment.
        # * EnvironmentName<~String>: The name of the environment whose configuration options you want to describe.
        # * Options<~Array>: If specified, restricts the descriptions to only the specified options.
        # * SolutionStackName<~String>: The name of the solution stack whose configuration options you want to describe.
        # * TemplateName<~String>: The name of the configuration template whose configuration options you want to describe.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeConfigurationOptions.html
        #
        def describe_configuration_options(options={})
          if option_filters = options.delete('Options')
            options.merge!(AWS.indexed_param('Options.member.%d', [*option_filters]))
          end
          request({
                      'Operation'    => 'DescribeConfigurationOptions',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::DescribeConfigurationOptions.new
                  }.merge(options))
        end
      end
    end
  end
end
