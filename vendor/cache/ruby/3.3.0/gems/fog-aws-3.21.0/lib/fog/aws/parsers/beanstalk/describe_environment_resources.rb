module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class DescribeEnvironmentResources < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("DescribeEnvironmentResourcesResult")
            tag 'EnvironmentResources', :object
            tag 'AutoScalingGroups', :object, :list
            tag 'Name', :string
            tag 'EnvironmentName', :string
            tag 'Instances', :object, :list
            tag 'Id', :string
            tag 'LaunchConfigurations', :object, :list
            tag 'LoadBalancers', :object, :list
            tag 'Resources', :object, :list
            tag 'Description', :string
            tag 'LogicalResourceId', :string
            tag 'PhysicalResourceId', :string
            tag 'Type', :string
            tag 'Properties', :object, :list
            tag 'RuntimeSources', :object, :list
            tag 'Parameter', :string
            tag 'Versions', :object, :list
            tag 'ApplicationName', :string
            tag 'VersionLabel', :string
            tag 'Triggers', :object, :list
          end
        end
      end
    end
  end
end
