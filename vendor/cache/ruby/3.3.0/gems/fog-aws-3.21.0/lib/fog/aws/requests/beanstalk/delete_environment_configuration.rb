module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/empty'

        # Deletes the draft configuration associated with the running environment.
        #
        # ==== Options
        # * application_name<~String>: The name of the application the environment is associated with.
        # * environment_name<~String>: The name of the environment to delete the draft configuration from.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DeleteConfigurationTemplate.html
        #
        def delete_environment_configuration(application_name, environment_name)
          options = {
              'ApplicationName' => application_name,
              'EnvironmentName' => environment_name
          }

          request({
                      'Operation'    => 'DeleteEnvironmentConfiguration',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::Empty.new
                  }.merge(options))
        end
      end
    end
  end
end
