module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/empty'

        # Deletes the specified version from the specified application.
        #
        # ==== Options
        # * application_name<~String>: The name of the application to delete releases from.
        # * version_label<~String>: The label of the version to delete.
        # * delete_source_bundle<~Boolean>: Indicates whether to delete the associated source bundle from Amazon S3.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DeleteApplication.html
        #
        def delete_application_version(application_name, version_label, delete_source_bundle = nil)
          options = {
              'ApplicationName' => application_name,
              'VersionLabel' => version_label
          }
          options['DeleteSourceBundle'] = delete_source_bundle unless delete_source_bundle.nil?

          request({
                      'Operation'    => 'DeleteApplicationVersion',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::Empty.new
                  }.merge(options))
        end
      end
    end
  end
end
