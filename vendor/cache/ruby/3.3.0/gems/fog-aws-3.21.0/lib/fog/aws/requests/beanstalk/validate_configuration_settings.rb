module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/validate_configuration_settings'

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
        def validate_configuration_settings(options={})
          if option_settings = options.delete('OptionSettings')
            options.merge!(AWS.indexed_param('OptionSettings.member.%d', [*option_settings]))
          end
          request({
                      'Operation'    => 'ValidateConfigurationSettings',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::ValidateConfigurationSettings.new
                  }.merge(options))
        end
      end
    end
  end
end
