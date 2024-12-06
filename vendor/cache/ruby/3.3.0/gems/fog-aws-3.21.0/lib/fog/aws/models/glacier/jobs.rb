require 'fog/aws/models/glacier/job'

module Fog
  module AWS
    class Glacier
      class Jobs < Fog::Collection
        model Fog::AWS::Glacier::Job
        attribute :vault
        attribute :filters

        def initialize(attributes)
          self.filters = {}
          super
        end

        # acceptable filters are:
        # statuscode InProgress/Failed/Succeeded
        # completed (true/false)
        def all(filters = self.filters)
          self.filters = filters
          data = service.list_jobs(vault.id, self.filters).body['JobList']
          load(data)
        end

        def get(key)
          data = service.describe_job(vault.id, key).body
          new(data)
        rescue Excon::Errors::NotFound
          nil
        end

        def new(attributes = {})
          requires :vault
          super({ :vault => vault }.merge!(attributes))
        end
      end
    end
  end
end
