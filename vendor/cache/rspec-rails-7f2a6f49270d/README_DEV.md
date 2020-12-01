# rspec-rails development

This documentation is meant for folks contributing the rspec-rails project
itself.

## Background

rspec-rails lives in a complicated ecosystem. We run our specs against multiple
Rails and Ruby versions.

### Default

By default, rspec-rails' test suite will run against the latest stable version
of Rails.

### Running Tests

```bash
bundle install --binstubs
bin/rake
```

### Errors

If you receive an error from `bundler` where constraints cannot be satisfied
for Rails, try removing `Gemfile.lock` (`rm Gemfile.lock`) and running `bundle
install --binstubs` again.

This can happen if the `Gemfile.lock` was generated for a different version of
Rails than you are trying to use now.

### Changing Rails Version

To run the specs against a different version of Rails, use the `thor` command:

```bash
bin/thor version:use 6.0.2.2
bin/rake
```
