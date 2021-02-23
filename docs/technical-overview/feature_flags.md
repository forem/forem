# Feature flags

We sometimes employ feature flags to develop features that aren't fully formed
at the moment of deployment. They can also be employed to roll out features in
production incrementally.

Feature flags are meant to be temporary and part of a rollout plan resulting in
their removal.

## Creating a new feature flag

To create a new feature flag, we use
[data update scripts](/backend/data-update-scripts) so that they can be made
available over the entire Forem fleet, for example:

```shell
bundle exec rails g data_update AddAwesomeAlgorithmFeatureFlag
```

This will generate a script and its spec. Once done, you can add the new feature
flag like this:

```ruby
module DataUpdateScripts
  class AddAwesomeAlgorithmFeatureFlag
    def run
      FeatureFlag.add(:awesome_algorithm)
    end
  end
end
```

and then start using it right away.

## Guarding a feature behind a flag

Once the feature flag is added, you can start using it to hide the feature
behind a boolean flag:

```ruby
if FeatureFlag.enabled?(:awesome_algorithm)
  # call the new code
else
  # call the previous code
end
```

or, for example in a view:

```erb
<% if FeatureFlag.enabled?(:blue_button) %>
  <%= render "blue_button" %>
<% else %>
  <%= render "good_old_button" %>
<% end %>
```

## Enabling/disabling a feature flag globally

As mentioned, feature flags can be used to test a work in progress feature or to
test a new approach directly in production.

To enable such a feature:

- Log in to the Forem
- Go to `/admin/feature_flags` (it requires the
  [`tech_admin` role](/backend/roles))
- Click on the flag you want to enable and press "Fully Enable".

![A screenshot of the Admin Feature Flag Panel](/admin_feature_flags.png)

## Removing a feature flag

Once the feature has been validated and finalized or discarded, please remember
to remove its flag with a final data update script, for example:

```shell
bundle exec rails g data_update RemoveAwesomeAlgorithmFeatureFlag
```

```ruby
module DataUpdateScripts
  class AwesomeAlgorithmFeatureFlag
    def run
      FeatureFlag.remove(:awesome_algorithm)
    end
  end
end
```

This will ensure that the feature will be removed from all Forems.
