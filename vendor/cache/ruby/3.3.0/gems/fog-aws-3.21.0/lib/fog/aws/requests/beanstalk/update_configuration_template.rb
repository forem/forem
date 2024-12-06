module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/update_configuration_template'

        # Updates the specified configuration template to have the specified properties or configuration option values.
        #
        # ==== Options
        # * ApplicationName<~String>: If specified, AWS Elastic Beanstalk restricts the returned descriptions
        #   to include only those that are associated with this application.
        # * VersionLabel<~String>:
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateConfigurationTemplate.html
        #
        def update_configuration_template(options={})
          if option_settings = options.delete('OptionSettings')
            options.merge!(AWS.indexed_param('OptionSettings.member.%d', [*option_settings]))
          end
          if options_to_remove = options.delete('OptionsToRemove')
            options.merge!(AWS.indexed_param('OptionsToRemove.member.%d', [*options_to_remove]))
          end
          request({
                      'Operation'    => 'UpdateConfigurationTemplate',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::UpdateConfigurationTemplate.new
                  }.merge(options))
        end
      end
    end
  end
end
