When you run `rails generate rspec:install`, the `spec/rails_helper.rb` file
includes the following configuration:

    RSpec.configure do |config|
      config.use_transactional_fixtures = true
    end

The name of this setting is a bit misleading. What it really means in Rails
is "run every test method within a transaction." In the context of rspec-rails,
it means "run every example within a transaction."

The idea is to start each example with a clean database, create whatever data
is necessary for that example, and then remove that data by simply rolling back
the transaction at the end of the example.

### Disabling transactions

If you prefer to manage the data yourself, or using another tool like
[database_cleaner](https://github.com/bmabey/database_cleaner) to do it for you,
simply tell RSpec to tell Rails not to manage transactions:

    RSpec.configure do |config|
      config.use_transactional_fixtures = false
    end

### Data created in `before(:example)` are rolled back

Any data you create in a `before(:example)` hook will be rolled back at the end of
the example. This is a good thing because it means that each example is
isolated from state that would otherwise be left around by the examples that
already ran. For example:

    describe Widget do
      before(:example) do
        @widget = Widget.create
      end

      it "does something" do
        expect(@widget).to do_something
      end

      it "does something else" do
        expect(@widget).to do_something_else
      end
    end

The `@widget` is recreated in each of the two examples above, so each example
has a different object, _and_ the underlying data is rolled back so the data
backing the `@widget` in each example is new.

### Data created in `before(:context)` are _not_ rolled back

`before(:context)` hooks are invoked before the transaction is opened. You can use
this to speed things up by creating data once before any example in a group is
run, however, this introduces a number of complications and you should only do
this if you have a firm grasp of the implications. Here are a couple of
guidelines:

1.  Be sure to clean up any data in an `after(:context)` hook:

        before(:context) do
          @widget = Widget.create!
        end

        after(:context) do
          @widget.destroy
        end

    If you don't do that, you'll leave data lying around that will eventually
    interfere with other examples.

2.  Reload the object in a `before(:example)` hook.

        before(:context) do
          @widget = Widget.create!
        end

        before(:example) do
          @widget.reload
        end

      Even though database updates in each example will be rolled back, the
      object won't _know_ about those rollbacks so the object and its backing
      data can easily get out of sync.
