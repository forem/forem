module Fog
  module AWS
    class ElasticBeanstalk
      class Environment < Fog::Model
        identity :name, :aliases => 'EnvironmentName'
        attribute :id, :aliases => 'EnvironmentId'

        attribute :application_name, :aliases => 'ApplicationName'
        attribute :cname, :aliases => 'CNAME'
        attribute :cname_prefix, :aliases => 'CNAMEPrefix'
        attribute :created_at, :aliases => 'DateCreated'
        attribute :updated_at, :aliases => 'DateUpdated'
        attribute :updated_at, :aliases => 'DateUpdated'
        attribute :description, :aliases => 'Description'
        attribute :endpoint_url, :aliases => 'EndpointURL'
        attribute :health, :aliases => 'Health'
        attribute :resources, :aliases => 'Resources'
        attribute :solution_stack_name, :aliases => 'SolutionStackName'
        attribute :status, :aliases => 'Status'
        attribute :template_name, :aliases => 'TemplateName'
        attribute :version_label, :aliases => 'VersionLabel'
        attribute :option_settings, :aliases => 'OptionSettings'
        attribute :options_to_remove, :aliases => 'OptionsToRemove'

        def healthy?
          health == 'Green'
        end

        def ready?
          status == 'Ready'
        end

        def terminated?
          status == 'Terminated'
        end

        # Returns the current live resources for this environment
        def live_resources
          requires :id
          data = service.describe_environment_resources({'EnvironmentId' => id}).body['DescribeEnvironmentResourcesResult']['EnvironmentResources']
          data.delete('EnvironmentName') # Delete the environment name from the result, only return actual resources
          data
        end

        # Returns the load balancer object associated with the environment.
        def load_balancer(elb_connection = Fog::AWS[:elb])
          if resources.nil?
            elb_connection.load_balancers.get(live_resources['LoadBalancers'].first['Name'])
          else
            elb_connection.load_balancers.get(resources['LoadBalancer']['LoadBalancerName'])
          end
        end

        # Return events related to this version
        def events
          requires :id
          service.events.all({'EnvironmentId' => id})
        end

        # Restarts the app servers in this environment
        def restart_app_server
          requires :id
          service.restart_app_server({'EnvironmentId' => id})
          reload
        end

        # Rebuilds the environment
        def rebuild
          requires :id
          service.rebuild_environment({'EnvironmentId' => id})
          reload
        end

        def swap_cnames(source)
          requires :name
          service.swap_environment_cnames({
              'SourceEnvironmentName' => source.name,
              'DestinationEnvironmentName' => name
                                             })
          source.reload
          reload
        end

        # Return the version object for this environment
        def version
          requires :application_name, :version_label
          service.versions.get(application_name, version_label)
        end

        # Update the running version of this environment
        def version=(new_version)
          requires :id
          if new_version.is_a?(String)
            new_version_label = new_version
          elsif new_version.is_a?(Fog::AWS::ElasticBeanstalk::Version)
            new_version_label = new_version.label
          else
            raise "Unknown type for new_version, must be either String or Fog::AWS::ElasticBeanstalk::Version"
          end

          if new_version.nil?
            raise "Version label not specified."
          end

          data = service.update_environment({
              'EnvironmentId' => id,
              'VersionLabel' => new_version_label
                                        }).body['UpdateEnvironmentResult']

          merge_attributes(data)
        end

        def destroy
          requires :id
          service.terminate_environment({'EnvironmentId' => id})
          true
        end

        def save
          requires :name, :application_name
          requires_one :template_name, :solution_stack_name

          options = {
              'ApplicationName' => application_name,
              'CNAMEPrefix' => cname_prefix,
              'Description' => description,
              'EnvironmentName' => name,
              'OptionSettings' => option_settings,
              'OptionsToRemove' => options_to_remove,
              'SolutionStackName' => solution_stack_name,
              'TemplateName' => template_name,
              'VersionLabel' => version_label
          }
          options.delete_if {|key, value| value.nil?}

          data = service.create_environment(options).body['CreateEnvironmentResult']
          merge_attributes(data)
          true
        end
      end
    end
  end
end
