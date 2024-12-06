module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/empty'

        # Deletes the specified application along with all associated versions and configurations.
        #
        # ==== Options
        # * application_name<~String>: The name of the application to delete.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DeleteApplication.html
        #
        def delete_application(application_name)
          options = { 'ApplicationName' => application_name }
          request({
                      'Operation'    => 'DeleteApplication',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::Empty.new
                  }.merge(options))
        end
      end
    end
  end
end
