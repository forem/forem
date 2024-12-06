module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class CheckDNSAvailability < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("CheckDNSAvailabilityResult")
            tag 'FullyQualifiedCNAME', :string
            tag 'Available', :boolean
          end
        end
      end
    end
  end
end
