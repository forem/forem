module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class CreateStorageLocation < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("CreateStorageLocationResult")
            tag 'S3Bucket', :string
          end
        end
      end
    end
  end
end
