module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/create_configuration_template'

        # Creates a configuration template. Templates are associated with a specific application and are used to
        # deploy different versions of the application with the same configuration settings.
        #
        # ==== Options
        # * ApplicationName<~String>: The name of the application to associate with this configuration template.
        #   If no application is found with this name, AWS Elastic Beanstalk returns an InvalidParameterValue error.
        # * Description<~String>: Describes this configuration.
        # * EnvironmentId<~String>: The ID of the environment used with this configuration template.
        # * OptionSettings<~Hash>: If specified, AWS Elastic Beanstalk sets the specified configuration option
        #     to the requested value. The new value overrides the value obtained from the solution stack or the
        #     source configuration template.
        # * SolutionStackName<~String>: The name of the solution stack used by this configuration. The solution
        #     stack specifies the operating system, architecture, and application server for a configuration template.
        #     It determines the set of configuration options as well as the possible and default values.
        # * SourceConfiguration<~String>: If specified, AWS Elastic Beanstalk uses the configuration values from the
        #     specified configuration template to create a new configuration.
        # * TemplateName<~String>: The name of the configuration template.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateConfigurationTemplate.html
        #
        def create_configuration_template(options={})
          if option_settings = options.delete('OptionSettings')
            options.merge!(AWS.indexed_param('OptionSettings.member.%d', [*option_settings]))
          end
          if option_settings = options.delete('SourceConfiguration')
            options.merge!(AWS.serialize_keys('SourceConfiguration', option_settings))
          end
          request({
                      'Operation'    => 'CreateConfigurationTemplate',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::CreateConfigurationTemplate.new
                  }.merge(options))
        end
      end
    end
  end
end
