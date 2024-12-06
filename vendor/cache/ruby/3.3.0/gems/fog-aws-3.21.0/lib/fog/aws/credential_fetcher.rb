# frozen_string_literal: true

require 'securerandom'

module Fog
  module AWS
    module CredentialFetcher

      INSTANCE_METADATA_HOST = "http://169.254.169.254"
      INSTANCE_METADATA_TOKEN = "/latest/api/token"
      INSTANCE_METADATA_PATH = "/latest/meta-data/iam/security-credentials/"
      INSTANCE_METADATA_AZ = "/latest/meta-data/placement/availability-zone/"

      CONTAINER_CREDENTIALS_HOST = "http://169.254.170.2"

      module ServiceMethods
        def fetch_credentials(options)
          if options[:use_iam_profile] && Fog.mocking?
            return Fog::AWS::Compute::Mock.data[:iam_role_based_creds]
          end
          if options[:use_iam_profile]
            begin
              role_data = nil
              region = options[:region] || ENV["AWS_DEFAULT_REGION"]

              if ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"]
                connection = options[:connection] || Excon.new(CONTAINER_CREDENTIALS_HOST)
                credential_path = options[:credential_path] || ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"]
                role_data = connection.get(:path => credential_path, :idempotent => true, :expects => 200).body
                session = Fog::JSON.decode(role_data)

                if region.nil?
                  connection = options[:metadata_connection] || Excon.new(INSTANCE_METADATA_HOST)
                  token_header = fetch_credentials_token_header(connection, options[:disable_imds_v2])
                  region = connection.get(:path => INSTANCE_METADATA_AZ, :idempotent => true, :expects => 200, :headers => token_header).body[0..-2]
                end
              elsif ENV["AWS_WEB_IDENTITY_TOKEN_FILE"]
                params = {
                  :Action => "AssumeRoleWithWebIdentity",
                  :RoleArn => options[:role_arn] || ENV.fetch("AWS_ROLE_ARN"),
                  :RoleSessionName => options[:role_session_name] || ENV["AWS_ROLE_SESSION_NAME"] || "fog-aws-#{SecureRandom.hex}",
                  :WebIdentityToken => File.read(options[:aws_web_identity_token_file] || ENV.fetch("AWS_WEB_IDENTITY_TOKEN_FILE")),
                  :DurationSeconds => options[:duration] || 3600,
                  :Version => "2011-06-15",
                }

                sts_endpoint =
                  if ENV["AWS_STS_REGIONAL_ENDPOINTS"] == "regional" && region
                    "https://sts.#{region}.amazonaws.com"
                  else
                    "https://sts.amazonaws.com"
                  end

                connection = options[:connection] || Excon.new(sts_endpoint, :query => params)
                document = Nokogiri::XML(connection.get(:idempotent => true, :expects => 200).body)

                session = {
                  "AccessKeyId" => document.css("AccessKeyId").children.text,
                  "SecretAccessKey" => document.css("SecretAccessKey").children.text,
                  "Token" => document.css("SessionToken").children.text,
                  "Expiration" => document.css("Expiration").children.text,
                }

                if region.nil?
                  connection = options[:metadata_connection] || Excon.new(INSTANCE_METADATA_HOST)
                  token_header = fetch_credentials_token_header(connection, options[:disable_imds_v2])
                  region = connection.get(:path => INSTANCE_METADATA_AZ, :idempotent => true, :expects => 200, :headers => token_header).body[0..-2]
                end
              else
                connection = options[:connection] || Excon.new(INSTANCE_METADATA_HOST)
                token_header = fetch_credentials_token_header(connection, options[:disable_imds_v2])
                role_name = connection.get(:path => INSTANCE_METADATA_PATH, :idempotent => true, :expects => 200, :headers => token_header).body
                role_data = connection.get(:path => INSTANCE_METADATA_PATH+role_name, :idempotent => true, :expects => 200, :headers => token_header).body
                session = Fog::JSON.decode(role_data)

                region ||= connection.get(:path => INSTANCE_METADATA_AZ, :idempotent => true, :expects => 200, :headers => token_header).body[0..-2]
              end

              credentials = {}
              credentials[:aws_access_key_id] = session['AccessKeyId']
              credentials[:aws_secret_access_key] = session['SecretAccessKey']
              credentials[:aws_session_token] = session['Token']
              credentials[:aws_credentials_expire_at] = Time.xmlschema session['Expiration']

              # set region by default to the one the instance is in.
              credentials[:region] = region
              credentials[:sts_endpoint] = sts_endpoint if sts_endpoint
              #these indicate the metadata service is unavailable or has no profile setup
              credentials
            rescue Excon::Error => e
              Fog::Logger.warning("Unable to fetch credentials: #{e.message}")
              super
            end
          else
            super
          end
        end

        def fetch_credentials_token_header(connection, disable_imds_v2)
          return nil if disable_imds_v2

          token = connection.put(
            :path => INSTANCE_METADATA_TOKEN,
            :idempotent => true,
            :expects => 200,
            :retry_interval => 1,
            :retry_limit => 3,
            :read_timeout => 1,
            :write_timeout => 1,
            :connect_timeout => 1,
            :headers => { "X-aws-ec2-metadata-token-ttl-seconds" => "300" }
          ).body

          { "X-aws-ec2-metadata-token" => token }
        rescue Excon::Error
          nil
        end
      end

      module ConnectionMethods
        def refresh_credentials_if_expired
          refresh_credentials if credentials_expired?
        end

        private

        # When defined, 'aws_credentials_refresh_threshold_seconds' controls
        # when the credential needs to be refreshed, expressed in seconds before
        # the current credential's expiration time
        def credentials_refresh_threshold
          @aws_credentials_refresh_threshold_seconds || 15
        end

        def credentials_expired?
          @use_iam_profile &&
            (!@aws_credentials_expire_at ||
             (@aws_credentials_expire_at && Fog::Time.now > @aws_credentials_expire_at - credentials_refresh_threshold)) #new credentials become available from around 5 minutes before expiration time
        end

        def refresh_credentials
          if @use_iam_profile
            new_credentials = service.fetch_credentials :use_iam_profile => @use_iam_profile, :region => @region
            if new_credentials.any?
              setup_credentials new_credentials
              return true
            else
              false
            end
          else
            false
          end
        end
      end
    end
  end
end
