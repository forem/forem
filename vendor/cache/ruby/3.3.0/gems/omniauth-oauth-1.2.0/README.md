# OmniAuth OAuth

This gem contains a generic OAuth strategy for OmniAuth. It is meant to
serve as a building block strategy for other strategies and not to be
used independently (since it has no inherent way to gather uid and user
info).

## Creating an OAuth Strategy

To create an OmniAuth OAuth strategy using this gem, you can simply
subclass it and add a few extra methods like so:

```ruby
require 'json'
require 'omniauth-oauth'

module OmniAuth
  module Strategies
    class SomeSite < OmniAuth::Strategies::OAuth
      # Give your strategy a name.
      option :name, "some_site"

      # This is where you pass the options you would pass when
      # initializing your consumer from the OAuth gem.
      option :client_options, {:site => "https://api.somesite.com"}

      # These are called after authentication has succeeded. If
      # possible, you should try to set the UID without making
      # additional calls (if the user id is returned with the token
      # or as a URI parameter). This may not be possible with all
      # providers.
      uid{ request.params['user_id'] }

      info do
        {
          :name => raw_info['name'],
          :location => raw_info['city']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= JSON.load(access_token.get('/me.json')).body
      end
    end
  end
end
```
