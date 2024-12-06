module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class CreateConfigurationTemplate < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("CreateConfigurationTemplateResult")
            tag 'ApplicationName', :string
            tag 'DateCreated', :datetime
            tag 'DateUpdated', :datetime
            tag 'DeploymentStatus', :string
            tag 'Description', :string
            tag 'EnvironmentName', :string
            tag 'OptionSettings', :object, :list
            tag 'Namespace', :string
            tag 'OptionName', :string
            tag 'Value', :string
            tag 'SolutionStackName', :string
            tag 'TemplateName', :string
          end
        end
      end
    end
  end
end
