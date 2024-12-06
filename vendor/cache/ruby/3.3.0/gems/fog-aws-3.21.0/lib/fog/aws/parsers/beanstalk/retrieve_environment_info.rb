module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class RetrieveEnvironmentInfo < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("RetrieveEnvironmentInfoResult")
            tag 'EnvironmentInfo', :object, :list
            tag 'Ec2InstanceId', :string
            tag 'InfoType', :string
            tag 'Message', :string
            tag 'SampleTimestamp', :datetime
          end
        end
      end
    end
  end
end
