module Fog
  module AWS
    class ElasticBeanstalk
      class Event < Fog::Model
        attribute :application_name, :aliases => 'ApplicationName'
        attribute :environment_name, :aliases => 'EnvironmentName'
        attribute :date, :aliases => 'EventDate'
        attribute :message, :aliases => 'Message'
        attribute :request_id, :aliases => 'RequestId'
        attribute :severity, :aliases => 'Severity'
        attribute :template_name, :aliases => 'TemplateName'
        attribute :version_label, :aliases => 'VersionLabel'
      end
    end
  end
end
