module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class UpdateApplicationVersion < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("UpdateApplicationVersionResult")
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
