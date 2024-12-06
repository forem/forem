# Notiffany

Notification library supporting popular notifiers, such as:
- Growl
- libnotify
- TMux
- Emacs (see: https://github.com/guard/notiffany/wiki/Emacs-support)
- rb-notifu
- notifysend
- gntp
- TerminalNotifier

## Features
- most popular notification libraries supported
- easy to override options at any level (new(), notify())
- using multiple notifiers simultaneously
- child processes reuse same configuration

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'notiffany'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install notiffany

## Usage

Basic notification

```ruby
notifier = Notiffany.connect(title: "A message")
notifier.notify("Hello there!", image: :success)
notifier.disconnect # some plugins like TMux and TerminalTitle rely on this
```

Enabling/disabling and on/off

### disable with option

```ruby
notifier = Notiffany.connect(notify: false)
notifier.notify('hello') # does nothing
```

### switch on/off using methods

```ruby
notifier = Notiffany.connect
notifier.turn_off
notifier.turn_on
notifier.toggle
```

### Customizing options

Options vary on the notifier type. The full list is here: https://github.com/guard/notiffany/tree/master/lib/notiffany/notifier

Currently, only TMux has "dynamic options". (Open an issue if you need this for other plugins).

"Dynamic options" means that you can have custom options (and custom defaults) for custom notifications.

Currently, the main notification types are: `success`, `pending`, `failed` and `notify`

For example, the default message format for TMux is: `default_message_format: "%s - %s"`

If you send a notification `success`, it will look for `success_message_format` and if that setting isn't available, it will fall back to `default_message_format`.

This means you can set colors for any notification type, e.g. you can set `foo_message_color`, for notifications of type `foo`.

Ideally in the future this would allow you to send custom notifications with custom icons, e.g. `foo_icon` which has a default value of `default_icon` for plugins that show icons, etc.

 

## Contributing

1. Fork it ( https://github.com/[my-github-username]/notiffany/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
