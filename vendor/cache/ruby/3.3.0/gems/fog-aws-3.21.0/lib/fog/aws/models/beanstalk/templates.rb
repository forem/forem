require 'fog/aws/models/beanstalk/template'

module Fog
  module AWS
    class ElasticBeanstalk
      class Templates < Fog::Collection
        model Fog::AWS::ElasticBeanstalk::Template

        # Describes all configuration templates, may optionally pass an ApplicationName filter
        #
        # Note: This is currently an expensive operation requiring multiple API calls due to a lack of
        # a describe configuration templates call in the AWS API.
        def all(options={})
          application_filter = []
          if options.key?('ApplicationName')
            application_filter << options['ApplicationName']
          end

          # Initialize with empty array
          data = []

          applications = service.describe_applications(application_filter).body['DescribeApplicationsResult']['Applications']
          applications.each { |application|
            application['ConfigurationTemplates'].each { |template_name|
              begin
                options = {
                    'ApplicationName' => application['ApplicationName'],
                    'TemplateName' => template_name
                }
                settings = service.describe_configuration_settings(options).body['DescribeConfigurationSettingsResult']['ConfigurationSettings']
                if settings.length == 1
                  # Add to data
                  data << settings.first
                end
              rescue Fog::AWS::ElasticBeanstalk::InvalidParameterError
                # Ignore
              end

            }
          }

          load(data) # data is an array of attribute hashes
        end

        def get(application_name, template_name)
          options = {
              'ApplicationName' => application_name,
              'TemplateName' => template_name
          }

          result = nil
          # There is no describe call for templates, so we must use describe_configuration_settings.  Unfortunately,
          # it throws an exception if template name doesn't exist, which is inconsistent, catch and return nil
          begin
            data = service.describe_configuration_settings(options).body['DescribeConfigurationSettingsResult']['ConfigurationSettings']
            if data.length == 1
              result = new(data.first)
            end
          rescue Fog::AWS::ElasticBeanstalk::InvalidParameterError

          end
            result
        end
      end
    end
  end
end
