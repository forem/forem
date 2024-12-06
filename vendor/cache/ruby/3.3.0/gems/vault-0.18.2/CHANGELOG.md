# Vault Ruby Changelog

## v?.??.? (Unreleased)

## v0.18.1 (September 14, 2023)

BUG FIXES

- Restored the ability to use this gem with older Ruby versions that do not have
  the `OpenSSL::SSL::TLS1_2_VERSION` constant.

## v0.18.0 (September 14, 2023)

IMPROVEMENTS

- Added support for TLS v1.3 by replacing `ssl_version` with `min_version`.

## v0.17.0 (May 11, 2022)

IMPROVEMENTS

- Added MissingRequiredStateErr error type to refer to 412s returned by Vault 1.10 when the WAL index on the node does not match the index in the Server-Side Consistent Token. This error type can be passed as a parameter to `#with_retries`, and will also be retried automatically when `#with_retries` is used with no parameters.

## v0.16.0 (March 17, 2021)

IMPROVEMENTS

- The timeout used to get a connection from the connection pool that talks with vault is now configurable. Using `Vault.pool_timeout` or the env var `VAULT_POOL_TIMEOUT`.

## v0.15.0 (July 29, 2020)

IMPROVEMENTS

- Added support for Resource Quotas

## v0.14.0 (May 28, 2020)

IMPROVEMENTS

- Added support for the Transform Secrets Engine

## v0.13.2 (May 7, 2020)

BUG FIXES

- Fixed the ability to use namespace as an option for each request. Previously, that option was ignored.
- aws-sigv4 gem was unlocked after a bug in 1.1.2 broke CI

## v0.13.1 (April 28, 2020)

IMPROVEMENTS

- Added support for defining a namespace when initializing the client, as well as options for changing the namespace via method.
- Added support for sys/namespaces API. Ability to Get, Create, Delete, and List namespaces has been provided.

## v0.13.0 (October 1, 2019)

IMPROVEMENTS

- Add support for versioned KV secrets in the client

## v0.12.0 (August 14, 2018)

IMPROVEMENTS

- Expose the github login path as an optional argument
- Support HTTP basic auth [GH-181]
- Expose the AWS IAM path to use [GH-180]
- Add GCP Auth [GH-173]
- Add shutdown functionality to close persistent connections [GH-175]

BUG FIXES

- Specifing the hostname for SNI didn't work. The functionality has been disabled for now.

## v0.11.0 (March 19, 2018)

IMPROVEMENTS

- Access to health has been added.
- Added ability to handle a Base64 encoded PEM (useful for certs in environment variables)
- Added IAM EC2 authentication support
- Add custom mount path support to TLS authentication

## v0.10.1 (May 8, 2017)

IMPROVEMENTS

- `vault-ruby` is licensed under Mozilla Public License 2.0, and has been for over 2 years. This patch release updates the gemspec to use the correct SPDX ID string for reporting this license, but **no change to the licensing of this gem has occurred**.


## v0.10.0 (April 19, 2017)

IMPROVEMENTS

- `#with_retries` now defaults to checking `HTTPServerError` if called without
  an error classes

BUG FIXES

- Don't randomly fail when parsing with Time.parse [GH-140]


## v0.9.0 (March 10, 2017)

IMPROVEMENTS

- The pool size used to talk with vault is now configurable. Using `Vault.pool_size` or the env var `VAULT_POOL_SIZE`.

## v0.8.0 (March 3, 2017)

BREAKING CHANGES

- Use PUT/POST for all functions that involve tokens [GH-117]. For Vault 0.6+,
  this will work as-expected. For older Vault versions, you will need to use an
  older client library which uses the URL instead. This is deprecated in Vault
  because the URL would include the token, thus revealing it in request logs.
  These new methods place the token in the body instead.

BUG FIXES

- Do not convert arrays in `#to_h` [GH-125]
- Prevent mismatched checkout/checkin from the connection pool; this will avoid masking errors that occur on pool checkout.

IMPROVEMENTS

- Support new init API options [GH-127]
- Return base64-encoded keys in init response [GH-128]
- Add support for `#hostname` for specifying SNI hostname to validate [GH-112]

## v0.7.3 (October 25, 2016)

BUG FIXES

- Allow options to be set on `Vault` as well as any `Vault::Client`
  instance to be used properly.
- Remove Ruby 2.0 syntax in favor of Ruby 1.9

## v0.7.2 (October 24, 2016)

BUG FIXES

- Set the default pool size to 16 rather than calculating from
  the number of available file descriptors.

## v0.7.1 (October 21, 2016)

BUG FIXES

- Properly vendor Net::HTTP::Persistent so that it doesn't collide
  with net-http-persistent
- Fix behavior where `verify_mode` was forced to `VERIFY_PEER`
  if a custom CA was set

## v0.7.0 (October 18, 2016)

DEPRECATIONS

- Vault versions older than 0.5.3 are no longer tested

NEW FEATURES

- Add support for AppRole
- Expose the auth/tune API
- Add support for leader step down
- Use persistent connections to Vault to speed up requests
- Add support for a custom ssl certificate store

BUG FIXES

- Allow for spaces in secret names properly

## v0.6.0 (August 30, 2016)

NEW FEATURES

- Add support for Vault 0.6.1 APIs
- Add new token `accessors` API method
- Add TLS authentication endpoints

BUG FIXES

- Restore old `to_h` behavior on response objects

IMPROVEMENTS

- Bootstrap full testing harness against old Vault versions

## v0.5.0 (August 16, 2016)

NEW FEATURES

- Add TTL wrapping to logical and auth backends
- Support passing PGP keys to init

BUG FIXES

- New API documentation
- Remove recursive requires

## v0.4.0 (March 31, 2016)

NEW FEATURES

- Add LDAP authentication method [GH-61]
- Add GitHub authentication method [GH-37]
- Add `create_orphan` method [GH-65]
- Add `lookup` and `lookup_self` for tokens
- Accept `VAULT_SKIP_VERIFY` environment variable [GH-66]

BUG FIXES

- Prefer `VAULT_TOKEN` environment variable over disk to mirror Vault's own
  behavior [GH-98]
- Do not duplicate query parameters on HEAD/GET requests [GH-62]
- Yield exception in `with_retries` [GH-68]

## v0.3.0 (February 16, 2016)

NEW FEATURES

- Add API for `renew_self`
- Add API for `revoke_self`
- Add API for listing secrets where supported

BUG FIXES

- Relax bundler constraint
- Fix race conditions on Ruby 2.3
- Escape path params before posting to Vault

## v0.2.0 (December 2, 2015)

IMPROVEMENTS

- Add support for retries (clients must opt-in) [GH-47]

BUG FIXES

- Fix redirection on POST/PUT [GH-40]
- Use `$HOME` instead of `~` for shell expansion

## v0.1.5 (September 1, 2015)

IMPROVEMENTS

- Use headers instead of cookies for authenticating to Vault [GH-36]

BUG FIXES

- Do not set undefined OpenSSL options
- Add `ssl_pem_passphrase` as a configuration option [GH-35]

## v0.1.4 (August 15, 2015)

IMPROVEMENTS

- Add support for using a custom CA cert [GH-8]
- Allow clients to specify timeouts [GH-12, GH-14]
- Show which error caused the HTTPConnectionError [GH-30]
- Allow clients to specify which SSL cipher suites to use [GH-29]
- Allow clients to specify the SSL pem password [GH-22, GH-31]

BUG FIXES

- Read local token (`~/.vault-token`) for token if present [GH-13]
- Disable bad SSL cipher suites and force TLSv1.2 [GH-16]
- Update to test against Vault 0.2.0 [GH-20]
- Do not attempt a read on logical path write [GH-11, GH-32]

## v0.1.3 (May 14, 2015)

BUG FIXES

- Decode logical response body if present

## v0.1.2 (May 3, 2015)

BUG FIXES

- Require vault/version before accessing Vault::VERSION in the client
- Improve Travis CI test coverage
- README and typo fixes

## v0.1.1 (April 4, 2015)

- Initial release
