module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/describe_application_versions'

        # Returns descriptions for existing application versions.
        #
        # ==== Options
        # * ApplicationName<~String>: If specified, AWS Elastic Beanstalk restricts the returned descriptions to
        #     only include ones that are associated with the specified application.
        # * VersionLabels<~Array>: If specified, restricts the returned descriptions to only include ones that have
        #     the specified version labels.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeApplicationVersions.html
        #
        def describe_application_versions(options={})
          if version_labels = options.delete('VersionLabels')
            options.merge!(AWS.indexed_param('VersionLabels.member.%d', [*version_labels]))
          end
          request({
                      'Operation'    => 'DescribeApplicationVersions',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::DescribeApplicationVersions.new
                  }.merge(options))
        end
      end
    end
  end
end
