---
title: Vault
---

## Installing

To install Vault follow the
[Vault installation](https://www.vaultproject.io/docs/install) instructions. If
you have a Mac, you can install
[Vault using Homebrew](https://formulae.brew.sh/formula/vault). You can validate
that you have it installed by running the following command.

```bash
vault -h
```

After Vault has been installed, the next step is to start up a Vault server.

```
vault server -dev
```

This will give you an output that looks like this:

```
==> Vault server configuration:

             Api Address: http://127.0.0.1:8200
                     Cgo: disabled
         Cluster Address: https://127.0.0.1:8201
              Listener 1: tcp (addr: "127.0.0.1:8200", cluster address: "127.0.0.1:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level: info
                   Mlock: supported: false, enabled: false
           Recovery Mode: false
                 Storage: inmem
                 Version: Vault v1.4.2
             Version Sha: 18f1c494be8b06788c2fdda1a4296eb3c4b174ce+CHANGES

WARNING! dev mode is enabled! In this mode, Vault runs entirely in-memory
and starts unsealed with a single unseal key. The root token is already
authenticated to the CLI, so you can immediately begin using Vault.

You may need to set the following environment variable:

    $ export VAULT_ADDR='http://127.0.0.1:8200'

The unseal key and root token are displayed below in case you want to
seal/unseal the Vault or re-authenticate.

Unseal Key: <a long key>
Root Token: <a token>

Development mode should NOT be used in production installations!
```

## Configuring

Once Vault is installed and running, the next step is to configure it to work
with your application. Since we want multiple applications (in production) to be
able to use the same Vault infrastructure, we control access with
[Vault policies](https://www.vaultproject.io/docs/concepts/policies) and
different
[key/value secret paths](https://www.vaultproject.io/docs/secrets/kv/kv-v2#setup).
In the following examples, `VAULT_SECRET_NAMESPACE` will be the secret path
where your secrets are stored. This can be any string (except "secrets" since
that exists by default) of your choosing, for example `local-secrets`.
`VAULT_POLICY_NAME` will be the name of the policy that we use to control access
to `VAULT_SECRET_NAMESPACE`. Once again, this should be a string. For example,
`local-policy`.

To set up a policy and secret path run the following commands:

```
vault secrets enable -path=<VAULT_SECRET_NAMESPACE>/ kv-v2

vault policy write VAULT_POLICY_NAME -<<EOF
# grant permission to new VAULT_SECRET_NAMESPACE path
path "VAULT_SECRET_NAMESPACE/data/*" {
  capabilities = ["create", "update", "read"]
}
EOF

vault token create -policy=VAULT_POLICY_NAME
```

The final command will give you the following output:

```
# Key                  Value
# ---                  -----
# token                important-policy-token
# token_accessor       another-less-important-token
# token_duration       768h
# token_renewable      true
# token_policies       ["default" VAULT_POLICY_NAME]
# identity_policies    []
# policies             ["default" VAULT_POLICY_NAME]
```

The `token` output from above is what you will use in your application to access
Vault. All that is left to do is set the appropriate ENV variables in your
`.env` file.

```shell
export VAULT_TOKEN=important-policy-token export VAULT_SECRET_NAMESPACE=<your
namespace from above>
```

Restart your application to start using Vault. One easy way to see it in action
is via the Rails console.

```ruby
# Enabled Example
[3] pry(main)> AppSecrets["TEST_SET"]="success"
=> "success"
[4] pry(main)> AppSecrets["TEST_SET"]
=> "success"

# Disabled Example
[2] pry(main)> AppSecrets["TEST_SET"]="success"
Vault::MissingTokenError: Missing Vault token! I cannot make requests to Vault without a token. Please
set a Vault token in the client:

    Vault.token = "1234"

or authenticate with Vault using the Vault CLI:

    $ vault auth ...

or set the environment variable $VAULT_TOKEN to the token value:

    $ export VAULT_TOKEN="..."

Please refer to the documentation for more examples.
```
