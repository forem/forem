module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/create_environment'

        # Launches an environment for the specified application using the specified configuration.
        #
        # ==== Options
        # * ApplicationName<~String>: If specified, AWS Elastic Beanstalk restricts the returned descriptions
        #     to include only those that are associated with this application.
        # * CNAMEPrefix<~String>: If specified, the environment attempts to use this value as the prefix for the CNAME.
        #     If not specified, the environment uses the environment name.
        # * Description<~String>: Describes this environment.
        # * EnvironmentName<~String>: A unique name for the deployment environment. Used in the application URL.
        # * OptionSettings<~Array>: If specified, AWS Elastic Beanstalk sets the specified configuration options to
        #     the requested value in the configuration set for the new environment. These override the values obtained
        #     from the solution stack or the configuration template.
        # * OptionsToRemove<~Array>: A list of custom user-defined configuration options to remove from the
        #     configuration set for this new environment.
        # * SolutionStackName<~String>: This is an alternative to specifying a configuration name. If specified,
        #     AWS Elastic Beanstalk sets the configuration values to the default values associated with the
        #     specified solution stack.
        # * TemplateName<~String>: The name of the configuration template to use in deployment. If no configuration
        #     template is found with this name, AWS Elastic Beanstalk returns an InvalidParameterValue error.
        # * VersionLabel<~String>: The name of the application version to deploy.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateEnvironment.html
        #
        def create_environment(options={})
          if option_settings = options.delete('OptionSettings')
            options.merge!(AWS.indexed_param('OptionSettings.member.%d', [*option_settings]))
          end
          if options_to_remove = options.delete('OptionsToRemove')
            options.merge!(AWS.indexed_param('OptionsToRemove.member.%d', [*options_to_remove]))
          end
          request({
                      'Operation'    => 'CreateEnvironment',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::CreateEnvironment.new
                  }.merge(options))
        end
      end
    end
  end
end
