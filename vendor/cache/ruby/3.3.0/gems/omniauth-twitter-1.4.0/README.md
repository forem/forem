# OmniAuth Twitter

[![Gem Version](https://badge.fury.io/rb/omniauth-twitter.svg)](http://badge.fury.io/rb/omniauth-twitter)
[![CI Build Status](https://secure.travis-ci.org/arunagw/omniauth-twitter.svg?branch=master)](http://travis-ci.org/arunagw/omniauth-twitter)
[![Code Climate](https://codeclimate.com/github/arunagw/omniauth-twitter.png)](https://codeclimate.com/github/arunagw/omniauth-twitter)

This gem contains the Twitter strategy for OmniAuth.

Twitter offers a few different methods of integration. This strategy implements the browser variant of the "[Sign in with Twitter](https://dev.twitter.com/docs/auth/implementing-sign-twitter)" flow.

Twitter uses OAuth 1.0a. Twitter's developer area contains ample documentation on how it implements this, so check that out if you are really interested in the details.

## Before You Begin

You should have already installed OmniAuth into your app; if not, read the [OmniAuth README](https://github.com/intridea/omniauth) to get started.

Now sign in into the [Twitter developer area](https://dev.twitter.com/apps) and create an application. Take note of your API Key and API Secret (not the Access Token and Access Token Secret) because that is what your web application will use to authenticate against the Twitter API. Make sure to set a callback URL or else you may get authentication errors. (It doesn't matter what it is, just that it is set.)

## Using This Strategy

First start by adding this gem to your Gemfile:

```ruby
gem 'omniauth-twitter'
```

If you need to use the latest HEAD version, you can do so with:

```ruby
gem 'omniauth-twitter', :github => 'arunagw/omniauth-twitter'
```

Next, tell OmniAuth about this provider. For a Rails app, your `config/initializers/omniauth.rb` file should look like this:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, "API_KEY", "API_SECRET"
end
```

Replace `"API_KEY"` and `"API_SECRET"` with the appropriate values you obtained [earlier](https://apps.twitter.com).

## Authentication Options

Twitter supports a [few options](https://dev.twitter.com/docs/api/1/get/oauth/authenticate) when authenticating. Usually you would specify these options as query parameters to the Twitter API authentication url (`https://api.twitter.com/oauth/authenticate` by default). With OmniAuth, of course, you use `http://yourapp.com/auth/twitter` instead. Because of this, this OmniAuth provider will pick up the query parameters you pass to the `/auth/twitter` URL and re-use them when making the call to the Twitter API.

The options are:

* **force_login** - This option sends the user to a sign-in screen to enter their Twitter credentials, even if they are already signed in. This is handy when your application supports multiple Twitter accounts and you want to ensure the correct user is signed in. *Example:* `http://yoursite.com/auth/twitter?force_login=true`

* **screen_name** - This option implies **force_login**, except the screen name field is pre-filled with a particular value. *Example:* `http://yoursite.com/auth/twitter?screen_name=jim`

* **lang** - The language used in the Twitter prompt. This is useful for adding i18n support since the language of the prompt can be dynamically set for each user. *Example:* `http://yoursite.com/auth/twitter?lang=pt`

* **secure_image_url** - Set to `true` to use https for the user's image url. Default is `false`.

* **image_size**: This option defines the size of the user's image. Valid options include `mini` (24x24), `normal` (48x48), `bigger` (73x73) and `original` (the size of the image originally uploaded). Default is `normal`.

* **x_auth_access_type** - This option (described [here](https://dev.twitter.com/docs/api/1/post/oauth/request_token)) lets you request the level of access that your app will have to the Twitter account in question. *Example:* `http://yoursite.com/auth/twitter?x_auth_access_type=read`

* **use_authorize** - There are actually two URLs you can use against the Twitter API. As mentioned, the default is `https://api.twitter.com/oauth/authenticate`, but you also have `https://api.twitter.com/oauth/authorize`. Passing this option as `true` will use the second URL rather than the first. What's the difference? As described [here](https://dev.twitter.com/docs/api/1/get/oauth/authenticate), with `authenticate`, if your user has already granted permission to your application, Twitter will redirect straight back to your application, whereas `authorize` forces the user to go through the "grant permission" screen again. For certain use cases this may be necessary. *Example:* `http://yoursite.com/auth/twitter?use_authorize=true`. *Note:* You must have "Allow this application to be used to Sign in with Twitter" checked in [your application's settings](https://dev.twitter.com/apps) - without it your user will be asked to authorize your application each time they log in.

Here's an example of a possible configuration where the the user's original profile picture is returned over https, the user is always prompted to sign-in and the default language of the Twitter prompt is changed:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, "API_KEY", "API_SECRET",
    {
      :secure_image_url => 'true',
      :image_size => 'original',
      :authorize_params => {
        :force_login => 'true',
        :lang => 'pt'
      }
    }
end
```

## Authentication Hash
An example auth hash available in `request.env['omniauth.auth']`:

```ruby
{
  :provider => "twitter",
  :uid => "123456",
  :info => {
    :nickname => "johnqpublic",
    :name => "John Q Public",
    :location => "Anytown, USA",
    :image => "http://si0.twimg.com/sticky/default_profile_images/default_profile_2_normal.png",
    :description => "a very normal guy.",
    :urls => {
      :Website => nil,
      :Twitter => "https://twitter.com/johnqpublic"
    }
  },
  :credentials => {
    :token => "a1b2c3d4...", # The OAuth 2.0 access token
    :secret => "abcdef1234"
  },
  :extra => {
    :access_token => "", # An OAuth::AccessToken object
    :raw_info => {
      :name => "John Q Public",
      :listed_count => 0,
      :profile_sidebar_border_color => "181A1E",
      :url => nil,
      :lang => "en",
      :statuses_count => 129,
      :profile_image_url => "http://si0.twimg.com/sticky/default_profile_images/default_profile_2_normal.png",
      :profile_background_image_url_https => "https://twimg0-a.akamaihd.net/profile_background_images/229171796/pattern_036.gif",
      :location => "Anytown, USA",
      :time_zone => "Chicago",
      :follow_request_sent => false,
      :id => 123456,
      :profile_background_tile => true,
      :profile_sidebar_fill_color => "666666",
      :followers_count => 1,
      :default_profile_image => false,
      :screen_name => "",
      :following => false,
      :utc_offset => -3600,
      :verified => false,
      :favourites_count => 0,
      :profile_background_color => "1A1B1F",
      :is_translator => false,
      :friends_count => 1,
      :notifications => false,
      :geo_enabled => true,
      :profile_background_image_url => "http://twimg0-a.akamaihd.net/profile_background_images/229171796/pattern_036.gif",
      :protected => false,
      :description => "a very normal guy.",
      :profile_link_color => "2FC2EF",
      :created_at => "Thu Jul 4 00:00:00 +0000 2013",
      :id_str => "123456",
      :profile_image_url_https => "https://si0.twimg.com/sticky/default_profile_images/default_profile_2_normal.png",
      :default_profile => false,
      :profile_use_background_image => false,
      :entities => {
        :description => {
          :urls => []
        }
      },
      :profile_text_color => "666666",
      :contributors_enabled => false
    }
  }
}
```

## Watch the RailsCast

Ryan Bates has put together an excellent RailsCast on OmniAuth:

[![RailsCast #241](http://railscasts.com/static/episodes/stills/241-simple-omniauth-revised.png "RailsCast #241 - Simple OmniAuth (revised)")](http://railscasts.com/episodes/241-simple-omniauth-revised)

## Supported Rubies

OmniAuth Twitter is tested under 2.1.x, 2.2.x and JRuby.

If you use its gem on ruby 1.9.x, 2.0.x, or Rubinius use version v1.2.1 .

## Contributing

Please read the [contribution guidelines](CONTRIBUTING.md) for some information on how to get started. No contribution is too small.

## License

Copyright (c) 2011 by Arun Agrawal

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
