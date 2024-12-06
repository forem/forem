module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class ListAvailableSolutionStacks < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("ListAvailableSolutionStacksResult")
            tag 'SolutionStackDetails', :object, :list
            tag 'PermittedFileTypes', :string, :list
            tag 'SolutionStackName', :string
            tag 'SolutionStacks', :string, :list
          end
        end
      end
    end
  end
end
