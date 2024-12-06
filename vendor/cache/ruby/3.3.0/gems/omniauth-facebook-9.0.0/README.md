# OmniAuth Facebook &nbsp;[![Build Status](https://secure.travis-ci.org/simi/omniauth-facebook.svg?branch=master)](https://travis-ci.org/simi/omniauth-facebook) [![Gem Version](https://img.shields.io/gem/v/omniauth-facebook.svg)](https://rubygems.org/gems/omniauth-facebook)

📣 **NOTICE** We’re looking for maintainers to help keep this project up-to-date. If you are interested in helping please open an Issue expressing your interest. Thanks! 📣

**These notes are based on master, please see tags for README pertaining to specific releases.**

Facebook OAuth2 Strategy for OmniAuth.

Supports OAuth 2.0 server-side and client-side flows. Read the Facebook docs for more details: http://developers.facebook.com/docs/authentication

## Installing

Add to your `Gemfile`:

```ruby
gem 'omniauth-facebook'
```

Then `bundle install`.

## Usage

`OmniAuth::Strategies::Facebook` is simply a Rack middleware. Read the OmniAuth docs for detailed instructions: https://github.com/intridea/omniauth.

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET']
end
```

[See the example Sinatra app for full examples](https://github.com/simi/omniauth-facebook/blob/master/example/config.ru) of both the server and client-side flows (including using the Facebook Javascript SDK).

## Configuring

You can configure several options, which you pass in to the `provider` method via a `Hash`:

Option name | Default | Explanation
--- | --- | ---
`scope` | `email` | A comma-separated list of permissions you want to request from the user. See the Facebook docs for a full list of available permissions: https://developers.facebook.com/docs/reference/login/
`display` | `page` | The display context to show the authentication page. Options are: `page`, `popup` and `touch`. Read the Facebook docs for more details: https://developers.facebook.com/docs/reference/dialogs/oauth/
`image_size` | `square` | Set the size for the returned image url in the auth hash. Valid options include `square` (50x50), `small` (50 pixels wide, variable height), `normal` (100 pixels wide, variable height), or `large` (about 200 pixels wide, variable height). Additionally, you can request a picture of a specific size by setting this option to a hash with `:width` and `:height` as keys. This will return an available profile picture closest to the requested size and requested aspect ratio. If only `:width` or `:height` is specified, we will return a picture whose width or height is closest to the requested size, respectively.
`info_fields` | `name,email` | Specify exactly which fields should be returned when getting the user's info. Value should be a comma-separated string as per https://developers.facebook.com/docs/graph-api/reference/user/ (only `/me` endpoint).
`locale` |  | Specify locale which should be used when getting the user's info. Value should be locale string as per https://developers.facebook.com/docs/reference/api/locale/.
`auth_type` | | Optionally specifies the requested authentication features as a comma-separated list, as per https://developers.facebook.com/docs/facebook-login/reauthentication/. Valid values are `https` (checks for the presence of the secure cookie and asks for re-authentication if it is not present), and `reauthenticate` (asks the user to re-authenticate unconditionally). Use 'rerequest' when you want to request premissions. Default is `nil`.
`secure_image_url` | `true` | Set to `true` to use https for the avatar image url returned in the auth hash. SSL is mandatory as per https://developers.facebook.com/docs/facebook-login/security#surfacearea.
`callback_url` / `callback_path` | | Specify a custom callback URL used during the server-side flow. Note this must be allowed by your app configuration on Facebook (see 'Valid OAuth redirect URIs' under the 'Advanced' settings section in the configuration for your Facebook app for more details).

For example, to request `email`, `user_birthday` and `read_stream` permissions and display the authentication page in a popup window:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'],
    scope: 'email,user_birthday,read_stream', display: 'popup'
end
```

### API Version

OmniAuth Facebook uses versioned API endpoints by default (current v5.0). You can configure a different version via `client_options` hash passed to `provider`, specifically you should change the version in the `site` and `authorize_url` parameters. For example, to change to v7.0 (assuming that exists):

```ruby
use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'],
    client_options: {
      site: 'https://graph.facebook.com/v7.0',
      authorize_url: "https://www.facebook.com/v7.0/dialog/oauth"
    }
end
```

### Per-Request Options

If you want to set the `display` format, `auth_type`, or `scope` on a per-request basis, you can just pass it to the OmniAuth request phase URL, for example: `/auth/facebook?display=popup` or `/auth/facebook?scope=email`.

## Auth Hash

Here's an example *Auth Hash* available in `request.env['omniauth.auth']`:

```ruby
{
  provider: 'facebook',
  uid: '1234567',
  info: {
    email: 'joe@bloggs.com',
    name: 'Joe Bloggs',
    first_name: 'Joe',
    last_name: 'Bloggs',
    image: 'http://graph.facebook.com/1234567/picture?type=square&access_token=...',
    verified: true
  },
  credentials: {
    token: 'ABCDEF...', # OAuth 2.0 access_token, which you may wish to store
    expires_at: 1321747205, # when the access token expires (it always will)
    expires: true # this will always be true
  },
  extra: {
    raw_info: {
      id: '1234567',
      name: 'Joe Bloggs',
      first_name: 'Joe',
      last_name: 'Bloggs',
      link: 'http://www.facebook.com/jbloggs',
      username: 'jbloggs',
      location: { id: '123456789', name: 'Palo Alto, California' },
      gender: 'male',
      email: 'joe@bloggs.com',
      timezone: -8,
      locale: 'en_US',
      verified: true,
      updated_time: '2011-11-11T06:21:03+0000',
      # ...
    }
  }
}
```

The precise information available may depend on the permissions which you request.

## Client-side Flow with Facebook Javascript SDK

You can use the Facebook Javascript SDK with `FB.login`, and just hit the callback endpoint (`/auth/facebook/callback` by default) once the user has authenticated in the success callback.

**Note that you must enable cookies in the `FB.init` config for this process to work.**

See the example Sinatra app under `example/` and read the [Facebook docs on Login for JavaScript](https://developers.facebook.com/docs/facebook-login/login-flow-for-web/) for more details.

### How it Works

The client-side flow is supported by parsing the authorization code from the signed request which Facebook places in a cookie.

When you call `/auth/facebook/callback` in the success callback of `FB.login` that will pass the cookie back to the server. omniauth-facebook will see this cookie and:

1. parse it,
2. extract the authorization code contained in it
3. and hit Facebook and obtain an access token which will get placed in the `request.env['omniauth.auth']['credentials']` hash.

## Token Expiry

The expiration time of the access token you obtain will depend on which flow you are using.

### Client-Side Flow

If you use the client-side flow, Facebook will give you back a short lived access token (~ 2 hours).

You can exchange this short lived access token for a longer lived version. Read the [Facebook docs](https://developers.facebook.com/docs/facebook-login/access-tokens/) for more information on exchanging a short lived token for a long lived token.

### Server-Side Flow

If you use the server-side flow, Facebook will give you back a longer lived access token (~ 60 days).

## Supported Rubies

- Ruby MRI (2.5, 2.6, 2.7, 3.0)

## License

Copyright (c) 2012 by Mark Dodwell

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
