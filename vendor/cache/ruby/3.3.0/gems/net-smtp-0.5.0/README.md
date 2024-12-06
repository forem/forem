# Net::SMTP

This library provides functionality to send internet mail via SMTP, the Simple Mail Transfer Protocol.

For details of SMTP itself, see [RFC2821](http://www.ietf.org/rfc/rfc2821.txt).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'net-smtp'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install net-smtp

## Usage

### Sending Messages

You must open a connection to an SMTP server before sending messages.
The first argument is the address of your SMTP server, and the second
argument is the port number. Using SMTP.start with a block is the simplest
way to do this. This way, the SMTP connection is closed automatically
after the block is executed.

```ruby
require 'net/smtp'
Net::SMTP.start('your.smtp.server', 25) do |smtp|
  # Use the SMTP object smtp only in this block.
end
```

Replace 'your.smtp.server' with your SMTP server. Normally
your system manager or internet provider supplies a server
for you.

Then you can send messages.

```ruby
msgstr = <<END_OF_MESSAGE
From: Your Name <your@mail.address>
To: Destination Address <someone@example.com>
Subject: test message
Date: Sat, 23 Jun 2001 16:26:43 +0900
Message-Id: <unique.message.id.string@example.com>

This is a test message.
END_OF_MESSAGE

require 'net/smtp'
Net::SMTP.start('your.smtp.server', 25) do |smtp|
  smtp.send_message msgstr,
                    'your@mail.address',
                    'his_address@example.com'
end
```

### Closing the Session

You MUST close the SMTP session after sending messages, by calling
the #finish method:

```ruby
# using SMTP#finish
smtp = Net::SMTP.start('your.smtp.server', 25)
smtp.send_message msgstr, 'from@address', 'to@address'
smtp.finish
```

You can also use the block form of SMTP.start/SMTP#start.  This closes
the SMTP session automatically:

```ruby
# using block form of SMTP.start
Net::SMTP.start('your.smtp.server', 25) do |smtp|
  smtp.send_message msgstr, 'from@address', 'to@address'
end
```

I strongly recommend this scheme.  This form is simpler and more robust.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/net-smtp.
