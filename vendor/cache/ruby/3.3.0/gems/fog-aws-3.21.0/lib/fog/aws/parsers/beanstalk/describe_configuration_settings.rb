module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class DescribeConfigurationSettings < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("DescribeConfigurationSettingsResult")
            tag 'ConfigurationSettings', :object, :list
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
