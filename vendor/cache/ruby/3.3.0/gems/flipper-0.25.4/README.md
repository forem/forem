[![Flipper Mark](docs/images/banner.jpg)](https://www.flippercloud.io)

[Website](https://flippercloud.io) | [Documentation](https://flippercloud.io/docs) | [Examples](examples) | [Twitter](https://twitter.com/flipper_cloud)

# Flipper

> Beautiful, performant feature flags for Ruby.

Flipper gives you control over who has access to features in your app.

* Enable or disable features for everyone, specific actors, groups of actors, a percentage of actors, or a percentage of time.
* Configure your feature flags from the console or a web UI.
* Regardless of what data store you are using, Flipper can performantly store your feature flags.
* Use [Flipper Cloud](#flipper-cloud) to cascade features from multiple environments, share settings with your team, control permissions, keep an audit history, and rollback.

Control your software &mdash; don't let it control you.

## Installation

Add this line to your application's Gemfile:

    gem 'flipper'

You'll also want to pick a storage [adapter](https://flippercloud.io/docs/adapters), for example:

    gem 'flipper-active_record'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper

## Subscribe &amp; Ship

[💌 &nbsp;Subscribe](https://buttondown.email/flipper) - I'll send you short and sweet emails when we release new versions.

## Getting Started

Use `Flipper#enabled?` in your app to check if a feature is enabled.

```ruby
# check if search is enabled
if Flipper.enabled? :search, current_user
  puts 'Search away!'
else
  puts 'No search for you!'
end
```

All features are disabled by default, so you'll need to explicitly enable them.

```ruby
# Enable a feature for everyone
Flipper.enable :search

# Enable a feature for a specific actor
Flipper.enable_actor :search, current_user

# Enable a feature for a group of actors
Flipper.enable_group :search, :admin

# Enable a feature for a percentage of actors
Flipper.enable_percentage_of_actors :search, 2
```

Read more about [getting started with Flipper](https://flippercloud.io/docs) and [enabling features](https://flippercloud.io/docs/features).

## Flipper Cloud

Like Flipper and want more? Check out [Flipper Cloud](https://www.flippercloud.io), which comes with:

* **everything in one place** &mdash; no need to bounce around from different application UIs or IRB consoles.
* **permissions** &mdash; grant access to everyone in your organization or lockdown each project to particular people.
* **multiple environments** &mdash; production, staging, enterprise, by continent, whatever you need.
* **personal environments** &mdash; no more rake scripts or manual enable/disable to get your laptop to look like production. Every developer gets a personal environment that inherits from production that they can override as they please ([read more](https://www.johnnunemaker.com/flipper-cloud-environments/)).
* **no maintenance** &mdash; we'll keep the lights on for you. We also have handy webhooks for keeping your app in sync with Cloud, so **our availability won't affect yours**. All your feature flag reads are local to your app.
* **audit history** &mdash; every feature change and who made it.
* **rollbacks** &mdash; enable or disable a feature accidentally? No problem. You can roll back to any point in the audit history with a single click.

[![Flipper Cloud Screenshot](docs/images/flipper_cloud.png)](https://www.flippercloud.io)

Cloud is super simple to integrate with Rails ([demo app](https://github.com/fewerandfaster/flipper-rails-demo)), Sinatra or any other framework.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run the tests (`bundle exec rake`). Check out [Docker-Compose](docs/DockerCompose.md) if you need help getting all the adapters running.
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

## Releasing

1. Update the version to be whatever it should be and commit.
2. `script/release`
3. Profit.

## Brought To You By

| pic | @mention | area |
|---|---|---|
| ![@jnunemaker](https://avatars3.githubusercontent.com/u/235?s=64) | [@jnunemaker](https://github.com/jnunemaker) | most things |
| ![@bkeepers](https://avatars3.githubusercontent.com/u/173?s=64) | [@bkeepers](https://github.com/bkeepers) | most things |
| ![@dpep](https://avatars3.githubusercontent.com/u/918804?s=64) | [@dpep](https://github.com/dpep) | tbd |
| ![@alexwheeler](https://avatars3.githubusercontent.com/u/3260042?s=64) | [@alexwheeler](https://github.com/alexwheeler) | api |
| ![@thetimbanks](https://avatars1.githubusercontent.com/u/471801?s=64) | [@thetimbanks](https://github.com/thetimbanks) | ui |
| ![@lazebny](https://avatars1.githubusercontent.com/u/6276766?s=64) | [@lazebny](https://github.com/lazebny) | docker |
