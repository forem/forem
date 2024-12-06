module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class DescribeEvents < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("DescribeEventsResult")
            tag 'Events', :object, :list
            tag 'ApplicationName', :string
            tag 'EnvironmentName', :string
            tag 'EventDate', :datetime
            tag 'Message', :string
            tag 'RequestId', :string
            tag 'Severity', :string
            tag 'TemplateName', :string
            tag 'VersionLabel', :string
            tag 'NextToken', :string
          end
        end
      end
    end
  end
end
