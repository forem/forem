module Fog
  module Parsers
    module AWS
      module ElasticBeanstalk
        require 'fog/aws/parsers/beanstalk/parser'
        class ValidateConfigurationSettings < Fog::Parsers::AWS::ElasticBeanstalk::BaseParser
          def initialize
            super("ValidateConfigurationSettingsResult")
            tag 'Messages', :object, :list
            tag 'Message', :string
            tag 'Namespace', :string
            tag 'OptionName', :string
            tag 'Severity', :string
          end
        end
      end
    end
  end
end
