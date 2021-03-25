# buffer

buffer is a Buffer API Wrapper written in Ruby.  It provides more thorough API coverage than the existing gem.

## Installation

[![Coverage Status](https://coveralls.io/repos/zph/buff/badge.png?branch=master)](https://coveralls.io/r/zph/buff?branch=master) [![Build Status](https://travis-ci.org/zph/buff.png?branch=master)](https://travis-ci.org/zph/buff) [![Code Climate](https://codeclimate.com/github/zph/buff.png)](https://codeclimate.com/github/zph/buff)

For now please `git clone git@github.com:bufferapp/buffer-ruby.git` the repo

Or

Add this line to your application's Gemfile to include HEAD code:

`gem 'buffer', :github => 'bufferapp/buffer-ruby'`

And then execute:

`$ bundle`

Or install RubyGems version, which will receive more attention to stability:

`$ gem install buffer`

## Usage

  * All methods are tested with Rspec and WebMock. Most methods do not have integration tests that reach out to the live Buffer API servers.  Proceed with caution until buffer reaches v0.1.0 and submit issues on Github Issues tab.
  * Authentication is not included in this gem (Try OAuth-buffer2) or use the single API key given when registering your own Buffer Dev credentials.
  * Commandline bin is provided to enable posting of updates:
    `buffer Super witty stuff that fits in 140 chars`
    Will post to your first account when setup following instructions below.
    _A more convenient setup is planned in future releases._
  * For convenience load credentials into environment as ENV variables:

```
export BUFFER_ACCESS_TOKEN="1/jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj" # (BufferApp OAuth Access Token)
export BUFFER_PROFILE_ID="0"                                    # (default of 0)
```

If you wish to post to multiple ids from the commandline, BUFFER_PROFILE_ID accepts a
comma delimited array of integers, ie `BUFFER_PROFILE_ID="0,1"`. This will post to both
0 and 1 index in your profiles list.

## Access Token Instructions

#### How to Get Started:

* Create a Developer API Token here: http://bufferapp.com/developers/apps/create.
* Fill in Stuff. Your answers don't matter much for the purpose of this rudimentary setup.
* Submit that form and wait a short period (~2 min )
* Visit: http://bufferapp.com/developers/apps
* Gather Access Token and place it after the word "access_token"
* Set BUFFER_PROFILE_ID="0" if you only have one account to post to. Otherwise it's more complicated ;).

#### Example

The example below will use your Buffer account and schedule an update to be posted on your connected profiles with the specified IDs.

```
client = Buffer::Client.new(ACCESS_TOKEN)
client.create_update(
  body: {
    text:
      "Today's artist spotlight is on #{artist_name}.
      Check out the track, #{track_title}.",
    profile_ids: [
      '...',
      '...',
    ]
  },
)
```

## TODO:

* Improve instructions

#### Future versions will integrate with Buffer-OAuth system.
* Integrate Launchy for the purpose of launching browser window.
* Possible to model behavior on [ t.gem ](https://github.com/sferik/t/blob/master/lib/t/cli.rb#L56-L113)

#### Raise error if message is beyond the character limit.
* Accomplish this via [ Twitter Text library ](https://github.com/twitter/twitter-text-rb)
* Refactor to simplify use of default params

## API Coverage

#### Implemented

* User
* Profiles (:get, :post)
* Updates (:get, :post)
* Links
* Info
* Error Codes

Further Details [API Coverage](API_COVERAGE.md)

#### Not Implemented

* Caching

## Supported Ruby Implementations
- MRI 2.0.0
- Others likely work but are not included in CI Server

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Issues, refactoring, and feedback are all welcome.

Also, this project is newcomer friendly!! We'd love to be your first Open Source Software contribution and would be happy to assist in that process.

Crafted with care by Zander. Reach out and say hi at [@_ZPH](http://twitter.com/_ZPH) or [civet.ws](http://www.civet.ws)
