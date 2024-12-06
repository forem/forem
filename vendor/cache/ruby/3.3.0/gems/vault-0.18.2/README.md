Vault Ruby Client [![Build Status](https://circleci.com/gh/hashicorp/vault-ruby.svg?style=shield)](https://circleci.com/gh/hashicorp/vault-ruby)
=================

Vault is the official Ruby client for interacting with [Vault](https://vaultproject.io) by HashiCorp.

**If you're viewing this README from GitHub on the `master` branch, know that it may contain unreleased features or
different APIs than the most recently released version. Please see the Git tag that corresponds to your version of the
Vault Ruby client for the proper documentation.**

Quick Start
-----------
Install Ruby 2.0+: [Guide](https://www.ruby-lang.org/en/documentation/installation/).

> Please note that as of Vault Ruby version 0.14.0 versions of Ruby prior to 2.0 are no longer supported.

Install via Rubygems:

    $ gem install vault

or add it to your Gemfile if you're using Bundler:

```ruby
gem "vault"
```

and then run the `bundle` command to install.

Start a Vault client:

```ruby
Vault.address = "http://127.0.0.1:8200" # Also reads from ENV["VAULT_ADDR"]
Vault.token   = "abcd-1234" # Also reads from ENV["VAULT_TOKEN"]
# Optional - if using the Namespace enterprise feature
# Vault.namespace   = "my-namespace" # Also reads from ENV["VAULT_NAMESPACE"]

Vault.sys.mounts #=> { :secret => #<struct Vault::Mount type="generic", description="generic secret storage"> }
```

Usage
-----
The following configuration options are available:

```ruby
Vault.configure do |config|
  # The address of the Vault server, also read as ENV["VAULT_ADDR"]
  config.address = "https://127.0.0.1:8200"

  # The token to authenticate with Vault, also read as ENV["VAULT_TOKEN"]
  config.token = "abcd-1234"
  # Optional - if using the Namespace enterprise feature
  # config.namespace   = "my-namespace" # Also reads from ENV["VAULT_NAMESPACE"]

  # Proxy connection information, also read as ENV["VAULT_PROXY_(thing)"]
  config.proxy_address  = "..."
  config.proxy_port     = "..."
  config.proxy_username = "..."
  config.proxy_password = "..."

  # Custom SSL PEM, also read as ENV["VAULT_SSL_CERT"]
  config.ssl_pem_file = "/path/on/disk.pem"

  # As an alternative to a pem file, you can provide the raw PEM string, also read in the following order of preference:
  # ENV["VAULT_SSL_PEM_CONTENTS_BASE64"] then ENV["VAULT_SSL_PEM_CONTENTS"]
  config.ssl_pem_contents = "-----BEGIN ENCRYPTED..."

  # Use SSL verification, also read as ENV["VAULT_SSL_VERIFY"]
  config.ssl_verify = false

  # Timeout the connection after a certain amount of time (seconds), also read
  # as ENV["VAULT_TIMEOUT"]
  config.timeout = 30

  # It is also possible to have finer-grained controls over the timeouts, these
  # may also be read as environment variables
  config.ssl_timeout  = 5
  config.open_timeout = 5
  config.read_timeout = 30
end
```

If you do not want the Vault singleton, or if you need to communicate with multiple Vault servers at once, you can create independent client objects:

```ruby
client_1 = Vault::Client.new(address: "https://vault.mycompany.com")
client_2 = Vault::Client.new(address: "https://other-vault.mycompany.com")
```

And if you want to authenticate with a `AWS EC2` :

```ruby
    # Export VAULT_ADDR to ENV then
    # Get the pkcs7 value from AWS
    signature = `curl http://169.254.169.254/latest/dynamic/instance-identity/pkcs7`
    iam_role = `curl http://169.254.169.254/latest/meta-data/iam/security-credentials/`
    vault_token = Vault.auth.aws_ec2(iam_role, signature, nil)
    vault_client = Vault::Client.new(address: ENV["VAULT_ADDR"], token: vault_token.auth.client_token)
```

### Making requests
All of the methods and API calls are heavily documented with examples inline using YARD. In order to keep the examples versioned with the code, the README only lists a few examples for using the Vault gem. Please see the inline documentation for the full API documentation. The tests in the 'spec' directory are an additional source of examples.

Idempotent requests can be wrapped with a `with_retries` clause to automatically retry on certain connection errors. For example, to retry on socket/network-level issues, you can do the following:

```ruby
Vault.with_retries(Vault::HTTPConnectionError) do
  Vault.logical.read("secret/on_bad_network")
end
```

To rescue particular HTTP exceptions:

```ruby
# Rescue 4xx errors
Vault.with_retries(Vault::HTTPClientError) {}

# Rescue 5xx errors
Vault.with_retries(Vault::HTTPServerError) {}

# Rescue all HTTP errors
Vault.with_retries(Vault::HTTPError) {}
```

For advanced users, the first argument of the block is the attempt number and the second argument is the exception itself:

```ruby
Vault.with_retries(Vault::HTTPConnectionError, Vault::HTTPError) do |attempt, e|
  if e
    log "Received exception #{e} from Vault - attempt #{attempt}"
  end
  Vault.logical.read("secret/bacon")
end
```

The following options are available:

```ruby
# :attempts - The number of retries when communicating with the Vault server.
#   The default value is 2.
#
# :base - The base interval for retry exponential backoff. The default value is
#   0.05s.
#
# :max_wait - The maximum amount of time for a single exponential backoff to
#   sleep. The default value is 2.0s.

Vault.with_retries(Vault::HTTPError, attempts: 5) do
  # ...
end
```

After the number of retries have been exhausted, the original exception is raised.

```ruby
Vault.with_retries(Exception) do
  raise Exception
end #=> #<Exception>
```

#### Seal Status
```ruby
Vault.sys.seal_status
#=> #<Vault::SealStatus sealed=false, t=1, n=1, progress=0>
```

#### Create a Secret
```ruby
Vault.logical.write("secret/bacon", delicious: true, cooktime: "11")
#=> #<Vault::Secret lease_id="">
```

#### Retrieve a Secret
```ruby
Vault.logical.read("secret/bacon")
#=> #<Vault::Secret lease_id="">
```

#### Retrieve the Contents of a Secret
```ruby
secret = Vault.logical.read("secret/bacon")
secret.data #=> { :cooktime = >"11", :delicious => true }
```

### Response wrapping

```ruby
# Request new access token as wrapped response where the TTL of the temporary
# token is "5s".
wrapped = Vault.auth_token.create(wrap_ttl: "5s")

# Unwrap the wrapped response to get the final token using the initial temporary
# token from the first request.
unwrapped = Vault.logical.unwrap(wrapped.wrap_info.token)

# Extract the final token from the response.
token = unwrapped.data.auth.client_token
```

A helper function is also provided when unwrapping a token directly:

```ruby
# Request new access token as wrapped response where the TTL of the temporary
# token is "5s".
wrapped = Vault.auth_token.create(wrap_ttl: "5s")

# Unwrap wrapped response for final token using the initial temporary token.
token = Vault.logical.unwrap_token(wrapped)
```


Development
-----------
1. Clone the project on GitHub
2. Create a feature branch
3. Submit a Pull Request

Important Notes:

- **All new features must include test coverage.** At a bare minimum, Unit tests are required. It is preferred if you include integration tests as well.
- **The tests must be idempotent.** The HTTP calls made during a test should be able to be run over and over.
- **Tests are order independent.** The default RSpec configuration randomizes the test order, so this should not be a problem.
- **Integration tests require Vault**  Vault must be available in the path for the integration tests to pass.
   - **In order to be considered an integration test:** The test MUST use the `vault_test_client` or `vault_redirect_test_client` as the client. This spawns a process, or uses an already existing process from another test, to run against.
