![build](https://github.com/nhosoya/omniauth-apple/workflows/RSpec/badge.svg?branch=master&event=push)

# OmniAuth::Apple

OmniAuth strategy for [Sign In with Apple](https://developer.apple.com/sign-in-with-apple/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-apple'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-apple

## Usage

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :apple, ENV['CLIENT_ID'], '',
           {
             scope: 'email name',
             team_id: ENV['TEAM_ID'],
             key_id: ENV['KEY_ID'],
             pem: ENV['PRIVATE_KEY']
           }
end
```

## Configuring "Sign In with Apple"

_other Sign In with Apple guides:_
- ["How To" by janak amarasena (2019)](https://medium.com/identity-beyond-borders/how-to-configure-sign-in-with-apple-77c61e336003)
- [the docs, by Apple](https://developer.apple.com/sign-in-with-apple/)

### Look out for the values you need for your config
  1. your domain and subdomains, something like: `myapp.com`, `www.myapp.com`
  2. your redirect uri, something like: `https://myapp.com/users/auth/apple/callback` (check `rails routes` to be sure)
  3. omniauth's "client id" will be Apple's "bundle id", something like: `com.myapp`
  4. you will get the "team id" value from Apple when you create your _**App Id**_, something like: `H000000B`
  5. Apple will give you a `.p8` file, which you'll use to GENERATE your `:pem` value

### Steps

1. Log into your [Apple Developer Account](https://idmsa.apple.com/IDMSWebAuth/signin?appIdKey=891bd3417a7776362562d2197f89480a8547b108fd934911bcbea0110d07f757&path=%2Faccount%2F&rv=1)
    (if you don't have one, you can [create one here](https://appleid.apple.com/account?appId=632&returnUrl=https%3A%2F%2Fdeveloper.apple.com%2Faccount%2F))

2. Get an App Id with the "Sign In with Apple" capability
    - go to your [Identifiers](https://developer.apple.com/account/resources/identifiers/list) list
    - [start a new Identifier](https://developer.apple.com/account/resources/identifiers/add/bundleId) by clicking on the + sign in the Identifiers List
    - select _**App IDs**_ and click _**continue**_
    - select _**App**_ and _**continue**_
    - enter a description and a bundle id
    - check the **_"Sign In with Apple"_** capability
    - save it

3. Get a Services Id (which we will use as our client id)
    - go to your [Identifiers](https://developer.apple.com/account/resources/identifiers/list) list
    - [start a new Identifier](https://developer.apple.com/account/resources/identifiers/add/bundleId) by clicking on the + sign in the Identifiers List
    - select _**Services IDs**_ and click _**continue**_
    - enter a description and a bundle id
    - make sure **_"Sign In with Apple"_** is checked, then click _**configure**_
    - make sure the Primary App ID matches the App ID you configured earlier
    -  enter all the subdomains you might use (comma delimited):

        example.com,www.example.com

    - enter all the redirect URLS you might use (comma delimited):

       https://example.com/users/auth/apple/callback,https://example.com/users/auth/apple/callback

    -  save the "Sign In with Apple" capability config and the Service Id

4. Get a Secret Key
    - go to your [Keys](https://developer.apple.com/account/resources/authkeys/list) list
    - [start a new Key](https://developer.apple.com/account/resources/authkeys/add) by clicking on the + sign in the Keys List
    - enter a name
    - make sure **_"Sign In with Apple"_** is checked, then click _**configure**_
    - make sure the Primary App ID matches the App ID you configured earlier
    - save the "Sign In with Apple" capability
    - click "continue" to finish the Key config (you will be prompted to _**Download Your Key**_)
    - Apple will give you a `.p8` file, keep it safe and secure (don't commit it).

### Mapping Apple Values to OmniAuth Values
  - your `:team_id` is in the top-right of your App Id config (aka _**App ID Prefix**_), it looks like: `H000000B`
  - your `:client_id` is in the top-right of your Services Id config (aka _**Identifier**_), it looks like: `com.example`
  - your `:key_id` is on the left side of your Key Details page, it looks like: `XYZ000000`
  - your `:pem` is the content of the `.p8` file you got from Apple, _**with an extra newline at the end**_

  - example from a Devise config:

      ```ruby
        config.omniauth :apple, ENV['APPLE_SERVICE_BUNDLE_ID'], '', {
          scope: 'email name',
          team_id: ENV['APPLE_APP_ID_PREFIX'],
          key_id: ENV['APPLE_KEY_ID'],
          pem: ENV['APPLE_P8_FILE_CONTENT_WITH_EXTRA_NEWLINE']
        }
      ```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nhosoya/omniauth-apple.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
