module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class UpdateEnvironment < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("UpdateEnvironmentResult")
            tag 'ApplicationName', :string
            tag 'CNAME', :string
            tag 'DateCreated', :datetime
            tag 'DateUpdated', :datetime
            tag 'Description', :string
            tag 'EndpointURL', :string
            tag 'EnvironmentId', :string
            tag 'EnvironmentName', :string
            tag 'Health', :string
            tag 'Resources', :object
            tag 'LoadBalancer', :object
            tag 'Domain', :string
            tag 'LoadBalancerName', :string
            tag 'Listeners', :object, :list
            tag 'Port', :integer
            tag 'Protocol', :string
            tag 'SolutionStackName', :string
            tag 'Status', :string
            tag 'TemplateName', :string
            tag 'VersionLabel', :string
          end
        end
      end
    end
  end
end
