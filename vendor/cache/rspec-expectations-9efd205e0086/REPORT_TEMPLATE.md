<!---
This file was generated on 2020-12-25T18:48:30+00:00 from the rspec-dev repo.
DO NOT modify it by hand as your changes will get lost the next time it is generated.
-->

# Report template

```ruby
# frozen_string_literal: true

begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  gem "rspec", "3.7.0" # Activate the gem and version you are reporting the issue against.
end

puts "Ruby version is: #{RUBY_VERSION}"
require 'rspec/autorun'

RSpec.describe 'additions' do
  it 'returns 2' do
    expect(1 + 1).to eq(2)
  end

  it 'returns 1' do
    expect(3 - 1).to eq(-1)
  end
end
```

Simply copy the content of the appropriate template into a `.rb` file on your computer
and make the necessary changes to demonstrate the issue. You can execute it by running
`ruby rspec_report.rb` in your terminal.

You can then share your executable test case as a [gist](https://gist.github.com), or
simply paste the content into the issue description.
