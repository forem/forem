module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class CreateApplication < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("CreateApplicationResult")
            tag 'Application', :object
            tag 'Versions', :string, :list
            tag 'ConfigurationTemplates', :string, :list
            tag 'ApplicationName', :string
            tag 'Description', :string
            tag 'DateCreated', :datetime
            tag 'DateUpdated', :datetime
          end
        end
      end
    end
  end
end
