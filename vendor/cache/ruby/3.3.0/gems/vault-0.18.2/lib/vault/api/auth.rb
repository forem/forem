# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "json"

require_relative "secret"
require_relative "../client"

module Vault
  class Client
    # A proxy to the {Auth} methods.
    # @return [Auth]
    def auth
      @auth ||= Authenticate.new(self)
    end
  end

  class Authenticate < Request
    # Authenticate via the "token" authentication method. This authentication
    # method is a bit bizarre because you already have a token, but hey,
    # whatever floats your boat.
    #
    # This method hits the `/v1/auth/token/lookup-self` endpoint after setting
    # the Vault client's token to the given token parameter. If the self lookup
    # succeeds, the token is persisted onto the client for future requests. If
    # the lookup fails, the old token (which could be unset) is restored on the
    # client.
    #
    # @example
    #   Vault.auth.token("6440e1bd-ba22-716a-887d-e133944d22bd") #=> #<Vault::Secret lease_id="">
    #   Vault.token #=> "6440e1bd-ba22-716a-887d-e133944d22bd"
    #
    # @param [String] new_token
    #   the new token to try to authenticate and store on the client
    #
    # @return [Secret]
    def token(new_token)
      old_token    = client.token
      client.token = new_token
      json = client.get("/v1/auth/token/lookup-self")
      secret = Secret.decode(json)
      return secret
    rescue
      client.token = old_token
      raise
    end

    # Authenticate via the "app-id" authentication method. If authentication is
    # successful, the resulting token will be stored on the client and used for
    # future requests.
    #
    # @example
    #   Vault.auth.app_id(
    #     "aeece56e-3f9b-40c3-8f85-781d3e9a8f68",
    #     "3b87be76-95cf-493a-a61b-7d5fc70870ad",
    #   ) #=> #<Vault::Secret lease_id="">
    #
    # @example with a custom mount point
    #   Vault.auth.app_id(
    #     "aeece56e-3f9b-40c3-8f85-781d3e9a8f68",
    #     "3b87be76-95cf-493a-a61b-7d5fc70870ad",
    #     mount: "new-app-id",
    #   )
    #
    # @param [String] app_id
    # @param [String] user_id
    # @param [Hash] options
    #   additional options to pass to the authentication call, such as a custom
    #   mount point
    #
    # @return [Secret]
    def app_id(app_id, user_id, options = {})
      payload = { app_id: app_id, user_id: user_id }.merge(options)
      json = client.post("/v1/auth/app-id/login", JSON.fast_generate(payload))
      secret = Secret.decode(json)
      client.token = secret.auth.client_token
      return secret
    end

    # Authenticate via the "approle" authentication method. If authentication is
    # successful, the resulting token will be stored on the client and used for
    # future requests.
    #
    # @example
    #   Vault.auth.approle(
    #     "db02de05-fa39-4855-059b-67221c5c2f63",
    #     "6a174c20-f6de-a53c-74d2-6018fcceff64",
    #   ) #=> #<Vault::Secret lease_id="">
    #
    # @param [String] role_id
    # @param [String] secret_id (default: nil)
    #   It is required when `bind_secret_id` is enabled for the specified role_id
    #
    # @return [Secret]
    def approle(role_id, secret_id=nil)
      payload = { role_id: role_id }
      payload[:secret_id] = secret_id if secret_id
      json = client.post("/v1/auth/approle/login", JSON.fast_generate(payload))
      secret = Secret.decode(json)
      client.token = secret.auth.client_token
      return secret
    end

    # Authenticate via the "userpass" authentication method. If authentication
    # is successful, the resulting token will be stored on the client and used
    # for future requests.
    #
    # @example
    #   Vault.auth.userpass("sethvargo", "s3kr3t") #=> #<Vault::Secret lease_id="">
    #
    # @example with a custom mount point
    #   Vault.auth.userpass("sethvargo", "s3kr3t", mount: "admin-login") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] username
    # @param [String] password
    # @param [Hash] options
    #   additional options to pass to the authentication call, such as a custom
    #   mount point
    #
    # @return [Secret]
    def userpass(username, password, options = {})
      payload = { password: password }.merge(options)
      json = client.post("/v1/auth/userpass/login/#{encode_path(username)}", JSON.fast_generate(payload))
      secret = Secret.decode(json)
      client.token = secret.auth.client_token
      return secret
    end

    # Authenticate via the "ldap" authentication method. If authentication
    # is successful, the resulting token will be stored on the client and used
    # for future requests.
    #
    # @example
    #   Vault.auth.ldap("sethvargo", "s3kr3t") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] username
    # @param [String] password
    # @param [Hash] options
    #   additional options to pass to the authentication call, such as a custom
    #   mount point
    #
    # @return [Secret]
    def ldap(username, password, options = {})
      payload = { password: password }.merge(options)
      json = client.post("/v1/auth/ldap/login/#{encode_path(username)}", JSON.fast_generate(payload))
      secret = Secret.decode(json)
      client.token = secret.auth.client_token
      return secret
    end

    # Authenticate via the GitHub authentication method. If authentication is
    # successful, the resulting token will be stored on the client and used
    # for future requests.
    #
    # @example
    #   Vault.auth.github("mypersonalgithubtoken") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] github_token
    #
    # @return [Secret]
    def github(github_token, path="/v1/auth/github/login")
      payload = {token: github_token}
      json = client.post(path, JSON.fast_generate(payload))
      secret = Secret.decode(json)
      client.token = secret.auth.client_token
      return secret
    end

    # Authenticate via the AWS EC2 authentication method. If authentication is
    # successful, the resulting token will be stored on the client and used
    # for future requests.
    #
    # @example
    #   Vault.auth.aws_ec2("read-only", "pkcs7", "vault-nonce") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] role
    # @param [String] pkcs7
    #   pkcs7 returned by the instance identity document (with line breaks removed)
    # @param [String] nonce optional
    # @param [String] route optional
    #
    # @return [Secret]
    def aws_ec2(role, pkcs7, nonce = nil, route = nil)
      route ||= '/v1/auth/aws-ec2/login'
      payload = { role: role, pkcs7: pkcs7 }
      # Set a custom nonce if client is providing one
      payload[:nonce] = nonce if nonce
      json = client.post(route, JSON.fast_generate(payload))
      secret = Secret.decode(json)
      client.token = secret.auth.client_token
      return secret
    end

    # Authenticate via AWS IAM auth method by providing a AWS CredentialProvider (either ECS, AssumeRole, etc.)
    # If authentication is successful, the resulting token will be stored on the client and used
    # for future requests.
    #
    # @example
    #   Vault.auth.aws_iam("dev-role-iam", Aws::InstanceProfileCredentials.new, "vault.example.com", "https://sts.us-east-2.amazonaws.com") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] role
    # @param [CredentialProvider] credentials_provider
    #   https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/CredentialProvider.html
    # @param [String] iam_auth_header_value optional
    #   As of Jan 2018, Vault will accept ANY or NO header if none is configured by the Vault server admin
    # @param [String] sts_endpoint optional
    #   https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html
    # @param [String] route optional
    # @return [Secret]
    def aws_iam(role, credentials_provider, iam_auth_header_value = nil, sts_endpoint = 'https://sts.amazonaws.com', route = nil)
      require "aws-sigv4"
      require "base64"

      request_body   = 'Action=GetCallerIdentity&Version=2011-06-15'
      request_method = 'POST'

      route ||= '/v1/auth/aws/login'

      vault_headers = {
        'User-Agent' => Vault::Client::USER_AGENT,
        'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8'
      }

      vault_headers['X-Vault-AWS-IAM-Server-ID'] = iam_auth_header_value if iam_auth_header_value

      sig4_headers = Aws::Sigv4::Signer.new(
        service: 'sts',
        region: region_from_sts_endpoint(sts_endpoint),
        credentials_provider: credentials_provider
      ).sign_request(
        http_method: request_method,
        url: sts_endpoint,
        headers: vault_headers,
        body: request_body
      ).headers

      payload = {
        role: role,
        iam_http_request_method: request_method,
        iam_request_url: Base64.strict_encode64(sts_endpoint),
        iam_request_headers: Base64.strict_encode64(vault_headers.merge(sig4_headers).to_json),
        iam_request_body: Base64.strict_encode64(request_body)
      }

      json = client.post(route, JSON.fast_generate(payload))
      secret = Secret.decode(json)
      client.token = secret.auth.client_token
      return secret
    end

    # Authenticate via the GCP authentication method. If authentication is
    # successful, the resulting token will be stored on the client and used
    # for future requests.
    #
    # @example
    #   Vault.auth.gcp("read-only", "jwt", "gcp") #=> #<Vault::Secret lease_id="">
    #
    # @param [String] role
    # @param [String] jwt
    #   jwt returned by the instance identity metadata, or iam api
    # @param [String] path optional
    #   the path were the gcp auth backend is mounted
    #
    # @return [Secret]
    def gcp(role, jwt, path = 'gcp')
      payload = { role: role, jwt: jwt }
      json = client.post("/v1/auth/#{CGI.escape(path)}/login", JSON.fast_generate(payload))
      secret = Secret.decode(json)
      client.token = secret.auth.client_token
      return secret
    end

    # Authenticate via a TLS authentication method. If authentication is
    # successful, the resulting token will be stored on the client and used
    # for future requests.
    #
    # @example Sending raw pem contents
    #   Vault.auth.tls(pem_contents) #=> #<Vault::Secret lease_id="">
    #
    # @example Reading a pem from disk
    #   Vault.auth.tls(File.read("/path/to/my/certificate.pem")) #=> #<Vault::Secret lease_id="">
    #
    # @example Sending to a cert authentication backend mounted at a custom location
    #   Vault.auth.tls(pem_contents, 'custom/location') #=> #<Vault::Secret lease_id="">
    #
    # @param [String] pem (default: the configured SSL pem file or contents)
    #   The raw pem contents to use for the login procedure.
    #
    # @param [String] path (default: 'cert')
    #   The path to the auth backend to use for the login procedure.
    #
    # @param [String] name optional
    #   The named certificate role provided to the login request. 
    #
    # @return [Secret]
    def tls(pem = nil, path = 'cert', name: nil)
      new_client = client.dup
      new_client.ssl_pem_contents = pem if !pem.nil?

      opts = {}
      opts[:name] = name if name
      json = new_client.post("/v1/auth/#{CGI.escape(path)}/login", opts)
      secret = Secret.decode(json)
      client.token = secret.auth.client_token
      return secret
    end

    private

    # Parse an AWS region from a STS endpoint
    # STS in the China (Beijing) region (cn-north-1) is sts.cn-north-1.amazonaws.com.cn
    # Take care changing below regex with that edge case in mind
    #
    # @param [String] sts_endpoint
    #   https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html
    #
    # @return [String] aws region
    def region_from_sts_endpoint(sts_endpoint)
      valid_sts_endpoint = %r{https:\/\/sts\.?(.*)\.amazonaws\.com}.match(sts_endpoint)
      raise "Unable to parse STS endpoint #{sts_endpoint}" unless valid_sts_endpoint
      valid_sts_endpoint[1].empty? ? 'us-east-1' : valid_sts_endpoint[1]
    end
  end
end
