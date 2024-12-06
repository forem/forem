module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/update_application_version'

        # Updates the specified application version to have the specified properties.
        #
        # ==== Options
        # * ApplicationName<~String>: The name of the application associated with this version.
        # * VersionLabel<~String>: The name of the version to update.
        # * Description<~String>: A new description for this release.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_UpdateApplicationVersion.html
        #
        def update_application_version(options)
          request({
                      'Operation'    => 'UpdateApplicationVersion',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::UpdateApplicationVersion.new
                  }.merge(options))
        end
      end
    end
  end
end
