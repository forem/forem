# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Devise
        # Class to encpasulate extracting information from a Devise resource
        # Normally a devise resource would be an Active::Record instance
        class Resource
          def initialize(resource)
            @resource = resource
          end

          def id
            extract(:id) || extract(:uuid)
          end

          def email
            extract(:email)
          end

          def username
            extract(:username)
          end

          private

          def extract(method)
            @resource.send(method) if @resource.respond_to?(method)
          end
        end
      end
    end
  end
end
