# Upgrade Guide

## 1.0.0 - 2.0.0

1. See release notes: https://github.com/honeycombio/beeline-ruby/releases/tag/v2.0.0
1. This update requires no code changes, but you must be aware of certain instrumentation changes. New fields will be added to your dataset and other fields will be removed.
1. ActionController::Parameters will now result in extra fields, or nested json, depending on your unfurl settings.
1. aws.params are now exploded into separate fields.
1. request.error becomes error.
1. request.error_detail becomes error_detail
1. request.protocol becomes request.scheme

## 0.8.0 - 1.0.0

1. If you have a web application, remove beeline configuration from the `config.ru` file
1. If you have a rails application, run the honeycomb generator `bundle exec rails generate honeycomb {writekey} --dataset {dataset}`
1. Replace call to `Honeycomb.init` with the following (if using rails, this will now live in `config/initializers/honeycomb.rb`)
    ```ruby
    Honeycomb.configure do |config|
      config.write_key = "{writekey}"
      config.dataset = "{dataset}"
    end
    ```
1. Replace any `Rack::Honeycomb.add_field` calls with the following
    ```ruby
    Honeycomb.add_field("name", "value")
    ```
1. Replace any `Honeycomb.span` calls with the following
    ```ruby
    Honeycomb.start_span(name: "interesting") do |span|
      span.add_field("name", "value")
    end
    ```

## honeycomb-rails to beeline-ruby

1. Update Gemfile, remove `honeycomb-rails` and add `honeycomb-beeline`
1. Run `bundle install`
1. Remove the `honeycomb.rb` initializer from `config/initializers`
1. Add the following to the `config.ru` file
    ```ruby
    # config.ru
    require 'honeycomb-beeline'

    Honeycomb.init(writekey: 'YOUR_API_KEY', dataset: 'YOUR_DATASET')

    # these next two lines should already exist in some form in this file, it's important to init the honeycomb library before this
    require ::File.expand_path('../config/environment', __FILE__)
    run Rails.application
    ```
1. You can use the same write key and dataset from the honeycomb initialiser above, note: the honeycomb-beeline only supports sending events to one dataset. This is due to the fact that the new beeline will include traces for your application by default and these are only viewable from within the same dataset
1. Replace any `honeycomb_metadata` calls in your controllers like the following
    ```ruby
    def index
      @bees = Bee.all
      Rack::Honeycomb.add_field(request.env, :bees_count, @bees.count)
      # honeycomb_metadata[:bees_count] = @bees.count
    end
    ```
1. If you are manually using the libhoney client as well, it is suggested that you remove the usages of it and rely on the beeline.
1. Instrument interesting calls using the new `span` API as per the example below
    ```ruby
      class HomeController < ApplicationController
        def index
          Honeycomb.span do
            @interesting_information = perform_intensive_calculations(params[:honey])
          end
        end
      end
    ```
1. `honeycomb-rails` had the ability to automatically populate user information onto your events. Unfortunately `beeline-ruby` does not support this out of the box. You can use something like this snippet below to continue populating this (example for Devise)
    ```ruby
    class ApplicationController < ActionController::Base
      before_action do
        Rack::Honeycomb.add_field(request.env, "user.id", current_user.id)
        Rack::Honeycomb.add_field(request.env, "user.email", current_user.email)
      end
    end
    ```
1. (Optional) If you are using `Sequel` for database access there are some additional steps to configure
    ```ruby
    # config.ru
    require 'honeycomb-beeline'
    require 'sequel-honeycomb/auto_install'

    Honeycomb.init(writekey: 'YOUR_API_KEY', dataset: 'YOUR_DATASET')
    Sequel::Honeycomb::AutoInstall.auto_install!(honeycomb_client: Honeycomb.client, logger: Honeycomb.logger)

    # these next two lines should already exist in some form in this file, it's important to init the honeycomb library before this
    require ::File.expand_path('../config/environment', __FILE__)
    run Rails.application
    ```
