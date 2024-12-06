module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class CreateApplicationVersion < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("CreateApplicationVersionResult")
            tag 'ApplicationVersion', :object
            tag 'ApplicationName', :string
            tag 'DateCreated', :datetime
            tag 'DateUpdated', :datetime
            tag 'Description', :string
            tag 'SourceBundle', :object
            tag 'S3Bucket', :string
            tag 'S3Key', :string
            tag 'VersionLabel', :string
          end
        end
      end
    end
  end
end
