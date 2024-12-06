module Fog
  module AWS
    class ElasticBeanstalk
      class Real
        require 'fog/aws/parsers/beanstalk/describe_applications'

        # Returns the descriptions of existing applications.
        #
        # ==== Options
        # * application_names<~Array>: If specified, AWS Elastic Beanstalk restricts the returned descriptions
        #                               to only include those with the specified names.
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/elasticbeanstalk/latest/api/API_DescribeApplications.html
        #
        def describe_applications(application_names=[])
          options = {}
          options.merge!(AWS.indexed_param('ApplicationNames.member.%d', [*application_names]))
          request({
                      'Operation'    => 'DescribeApplications',
                      :parser     => Fog::Parsers::AWS::ElasticBeanstalk::DescribeApplications.new
                  }.merge(options))
        end
      end
    end
  end
end
