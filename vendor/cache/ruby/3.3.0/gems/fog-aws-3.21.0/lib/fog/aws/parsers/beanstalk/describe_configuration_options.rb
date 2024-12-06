module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class DescribeConfigurationOptions < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("DescribeConfigurationOptionsResult")
            tag 'SolutionStackName', :string
            tag 'Options', :object, :list
            tag 'ChangeSeverity', :string
            tag 'DefaultValue', :string
            tag 'MaxLength', :integer
            tag 'MaxValue', :integer
            tag 'MinValue', :integer
            tag 'Name', :string
            tag 'Namespace', :string
            tag 'Regex', :object
            tag 'Label', :string
            tag 'Pattern', :string
            tag 'UserDefined', :boolean
            tag 'ValueOptions', :string, :list
            tag 'ValueType', :string
          end
        end
      end
    end
  end
end
