# frozen_string_literal: true

module Anyway
  using RubyNext

  module Rails
    module Loaders
      class Credentials < Anyway::Loaders::Base
        LOCAL_CONTENT_PATH = "config/credentials/local.yml.enc"

        def call(name:, **_options)
          return {} unless ::Rails.application.respond_to?(:credentials)

          # do not load from credentials if we're in the context
          # of the `credentials:edit` command
          return {} if defined?(::Rails::Command::CredentialsCommand)

          # Create a new hash cause credentials are mutable!
          config = {}

          trace!(
            :credentials,
            store: credentials_path
          ) do
            ::Rails.application.credentials.config[name.to_sym]
          end.then do |creds|
            Utils.deep_merge!(config, creds) if creds
          end

          if use_local?
            trace!(:credentials, store: LOCAL_CONTENT_PATH) do
              local_credentials(name)
            end.then { |creds| Utils.deep_merge!(config, creds) if creds }
          end

          config
        end

        private

        def local_credentials(name)
          local_creds_path = ::Rails.root.join(LOCAL_CONTENT_PATH).to_s

          return unless File.file?(local_creds_path)

          creds = ::Rails.application.encrypted(
            local_creds_path,
            key_path: ::Rails.root.join("config/credentials/local.key")
          )

          creds.config[name.to_sym]
        end

        def credentials_path
          if ::Rails.application.config.respond_to?(:credentials)
            ::Rails.application.config.credentials.content_path.relative_path_from(::Rails.root).to_s
          else
            "config/credentials.yml.enc"
          end
        end
      end
    end
  end
end
