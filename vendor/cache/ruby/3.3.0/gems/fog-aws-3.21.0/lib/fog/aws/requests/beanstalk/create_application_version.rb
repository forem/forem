module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/create_application_version'

        # Creates an application version for the specified application.
        #
        # ==== Options
        # * ApplicationName<~String>: The name of the application. If no application is found with this name,
        #   and AutoCreateApplication is false, returns an InvalidParameterValue error.
        # * AutoCreateApplication<~Boolean>: If true, create the application if it doesn't exist.
        # * Description<~String>: Describes this version.
        # * SourceBundle<~Hash>: The Amazon S3 bucket and key that identify the location of the source bundle
        #     for this version.  Use keys 'S3Bucket' and 'S3Key' to describe location.
        # * VersionLabel<~String>: A label identifying this version.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_CreateApplicationVersion.html
        #
        def create_application_version(options={})
          if source_bundle = options.delete('SourceBundle')
            # flatten hash
            options.merge!({
                               'SourceBundle.S3Bucket' => source_bundle['S3Bucket'],
                               'SourceBundle.S3Key' => source_bundle['S3Key']
                           })
          end
          request({
                      'Operation'    => 'CreateApplicationVersion',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::CreateApplicationVersion.new
                  }.merge(options))
        end
      end
    end
  end
end
