module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/empty'

        # Deletes the specified configuration template.
        #
        # ==== Options
        # * application_name<~String>: The name of the application to delete the configuration template from.
        # * template_name<~String>: The name of the configuration template to delete.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DeleteConfigurationTemplate.html
        #
        def delete_configuration_template(application_name, template_name)
          options = {
              'ApplicationName' => application_name,
              'TemplateName' => template_name
          }

          request({
                      'Operation'    => 'DeleteConfigurationTemplate',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::Empty.new
                  }.merge(options))
        end
      end
    end
  end
end
