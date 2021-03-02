Historically, rspec-mocks has used a monkey-patched syntax to allow you to mock or stub any object:

```ruby
obj.stub(:foo).and_return(15)
obj.should_receive(:bar)
```

Unfortunately, this is prone to weird, confusing failures when applied to [delegate/proxy
objects](http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax#delegation_issues). For a method like `stub` to work properly, it must be defined on every object in the
system, but RSpec does not own every object in the system and cannot ensure that it always
works consistently.

For this reason, in RSpec 2.14, we introduced a new syntax that avoids monkey patching
altogether. It's the syntax shown in all examples of this documentation outside of this
directory. As of RSpec 3, we consider this to be the main, recommended syntax of rspec-
mocks. The old monkey-patched syntax continues to work, but you will get a deprecation
warning if you use it without explicitly opting-in to it:

```ruby
# If you're using rspec-core:
RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end
end

# Or, if you're using rspec-mocks in another context:
RSpec::Mocks.configuration.syntax = :should
```

We have no plans to ever kill the old syntax, but we may extract it into an external gem in
RSpec 4.

If you have an old project that uses the old syntax and you want to update it to the current
syntax, checkout [transpec](http://yujinakayama.me/transpec/).
