require 'fog/aws/models/beanstalk/version'

module Fog
  module AWS
    class ElasticBeanstalk
      class Versions < Fog::Collection
        model Fog::AWS::ElasticBeanstalk::Version

        def all(options={})
          data = service.describe_application_versions(options).body['DescribeApplicationVersionsResult']['ApplicationVersions']
          load(data) # data is an array of attribute hashes
        end

        def get(application_name, version_label)
          if data = service.describe_application_versions({
                                                                 'ApplicationName' => application_name,
                                                                 'VersionLabels' => [version_label]
                                                             }).body['DescribeApplicationVersionsResult']['ApplicationVersions']
            if data.length == 1
              new(data.first)
            end

          end
        end
      end
    end
  end
end
