module Fog
  module AWS
    class ElasticBeanstalk
      class Template < Fog::Model
        attribute :name, :aliases => 'TemplateName'
        attribute :application_name, :aliases => 'ApplicationName'
        attribute :created_at, :aliases => 'DateCreated'
        attribute :updated_at, :aliases => 'DateUpdated'
        attribute :deployment_status, :aliases => 'DeploymentStatus'
        attribute :description, :aliases => 'Description'
        attribute :environment_id
        attribute :environment_name, :aliases => 'EnvironmentName'
        attribute :solution_stack_name, :aliases => 'SolutionStackName'
        attribute :source_configuration
        attribute :option_settings, :aliases => 'OptionSettings'

        def initialize(attributes={})
          super
        end

        # Returns an array of options that may be set on this template
        def options
          requires :name, :application_name
          data = service.describe_configuration_options({
              'ApplicationName' => application_name,
              'TemplateName' => name
                                                    })
          data.body['DescribeConfigurationOptionsResult']['Options']
        end

        def destroy
          requires :name, :application_name
          service.delete_configuration_template(application_name, name)
          true
        end

        def save
          requires :name, :application_name

          options = {
              'ApplicationName' => application_name,
              'Description' => description,
              'EnvironmentId' => environment_id,
              'OptionSettings' => option_settings,
              'SolutionStackName' => solution_stack_name,
              'SourceConfiguration' => source_configuration,
              'TemplateName' => name
          }
          options.delete_if {|key, value| value.nil?}

          data = service.create_configuration_template(options).body['CreateConfigurationTemplateResult']
          merge_attributes(data)
          true
        end

        def modify(new_attributes)
          requires :name, :application_name

          options = {
              'ApplicationName' => application_name,
              'Description' => new_attributes[:description],
              'OptionSettings' => new_attributes[:option_settings],
              'TemplateName' => name
          }
          options.delete_if {|key, value| value.nil?}

          data = service.update_configuration_template(options).body['UpdateConfigurationTemplateResult']
          merge_attributes(data)
          true
        end
      end
    end
  end
end
