# Cuprite - Headless Chrome driver for Capybara

Cuprite is a pure Ruby driver (read as _no_ Selenium/WebDriver/ChromeDriver
dependency) for [Capybara](https://github.com/teamcapybara/capybara). It allows
you to run Capybara tests on a headless Chrome or Chromium. Under the hood it
uses [Ferrum](https://github.com/rubycdp/ferrum#index) which is high-level API
to the browser by CDP protocol. The design of the driver is as close to
[Poltergeist](https://github.com/teampoltergeist/poltergeist) as possible though
it's not a goal.


## Install

Add this to your `Gemfile` and run `bundle install`.

``` ruby
group :test do
  gem "cuprite"
end
```

In your test setup add:

``` ruby
require "capybara/cuprite"
Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 800])
end
```

if you use `Docker` don't forget to pass `no-sandbox` option:

```ruby
Capybara::Cuprite::Driver.new(app, browser_options: { 'no-sandbox': nil })
```

Since Cuprite uses [Ferrum](https://github.com/rubycdp/ferrum#examples) there
are many useful methods you can call even using this driver:

```ruby
browser = page.driver.browser
browser.mouse.move(x: 123, y: 456).down.up
```

If you already have tests on Poltergeist then it should simply work, for
Selenium you better check your code for `manage` calls because it works
differently in Cuprite, see the documentation below.


## Customization

See the full list of options for
[Ferrum](https://github.com/rubycdp/ferrum#customization).

You can pass options with the following code in your test setup:

``` ruby
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, options)
end
```

`Cuprite`-specific options are:

* options `Hash`
  * `:url_blacklist` (Array) - array of strings to match against requested URLs
  * `:url_whitelist` (Array) - array of strings to match against requested URLs


## Debugging

If you pass `inspector` option, remote debugging will be enabled if you run
tests with `INSPECTOR=true`. Then you can put `page.driver.debug` or
`page.driver.debug(binding)` in your test to pause it. This will launch the
browser where you can inspect the content.

```ruby
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app, inspector: ENV['INSPECTOR'])
end
```

then somewhere in the test:

```ruby
it "does something useful" do
  visit root_path

  fill_in "field", with: "value"
  page.driver.debug(binding)

  expect(page).to have_content("value")
end
```

In the middle of the execution Chrome will open a new tab where you can inspect
the content and also if you passed `binding` an `irb` or `pry` console will be
opened where you can further experiment with the test.


## Clicking/Scrolling

* `page.driver.click(x, y)` Click a very specific area of the screen.
* `page.driver.scroll_to(left, top)` Scroll to a given position.
* `element.send_keys(*keys)` Send keys to a given node.


## Request headers

Manipulate HTTP request headers like a boss:

``` ruby
page.driver.headers # => {}
page.driver.headers = { "User-Agent" => "Cuprite" }
page.driver.add_headers("Referer" => "https://example.com")
page.driver.headers # => { "User-Agent" => "Cuprite", "Referer" => "https://example.com" }
```

Notice that `headers=` will overwrite already set headers. You should use
`add_headers` if you want to add a few more. These headers will apply to all
subsequent HTTP requests (including requests for assets, AJAX, etc). They will
be automatically cleared at the end of the test.


## Network traffic

* `page.driver.network_traffic` Inspect network traffic (loaded resources) on
the current page. This returns an array of request objects.

```ruby
page.driver.network_traffic # => [Request, ...]
request = page.driver.network_traffic.first
request.response
```

* `page.driver.wait_for_network_idle` Natively waits for network idle and if
there are no active connections returns or raises `TimeoutError` error. Accepts
the same options as
[`wait_for_idle`](https://github.com/rubycdp/ferrum#wait_for_idleoptions)

```ruby
page.driver.wait_for_network_idle
page.driver.refresh
```

Please note that network traffic is not cleared when you visit new page. You can
manually clear the network traffic by calling `page.driver.clear_network_traffic`
or `page.driver.reset`

* `page.driver.wait_for_reload` unlike `wait_for_network_idle` will wait until
the whole page is reloaded or raise a timeout error. It's useful when you know
that for example after clicking autocomplete suggestion you expect page to be
reloaded, you have a few choices - put sleep or wait for network idle, but both
are bad. Sleep makes you wait longer or less than needed, network idle can
return earlier even before the whole page is started to reload. Here's the
rescue.


## Manipulating cookies

The following methods are used to inspect and manipulate cookies:

* `page.driver.cookies` - a hash of cookies accessible to the current
  page. The keys are cookie names. The values are `Cookie` objects, with
  the following methods: `name`, `value`, `domain`, `path`, `size`, `secure?`,
  `httponly?`, `session?`, `expires`.
* `page.driver.set_cookie(name, value, options = {})` - set a cookie.
  The options hash can take the following keys: `:domain`, `:path`,
  `:secure`, `:httponly`, `:expires`. `:expires` should be a
  `Time` object.
* `page.driver.remove_cookie(name)` - remove a cookie
* `page.driver.clear_cookies` - clear all cookies


## Screenshot

Besides capybara screenshot method you can get image as Base64:

* `page.driver.render_base64(format, options)`


## Authorization

* `page.driver.basic_authorize(user, password)`

## Proxy

* `page.driver.set_proxy(ip, port, type, user, password)`


## URL Blacklisting & Whitelisting

Cuprite supports URL blacklisting, which allows you to prevent scripts from
running on designated domains:

```ruby
page.driver.browser.url_blacklist = %r{http://www.example.com}
```

and also URL whitelisting, which allows scripts to only run on designated
domains:

```ruby
page.driver.browser.url_whitelist = %r{http://www.example.com}
```

If you are experiencing slower run times, consider creating a URL whitelist of
domains that are essential or a blacklist of domains that are not essential,
such as ad networks or analytics, to your testing environment.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
