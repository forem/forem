# Ferrum - high-level API to control Chrome in Ruby

<img align="right"
     width="320" height="241"
     alt="Ferrum logo"
     src="https://raw.githubusercontent.com/rubycdp/ferrum/main/logo.svg?sanitize=true">

#### As simple as Puppeteer, though even simpler.

It is Ruby clean and high-level API to Chrome. Runs headless by default, but you
can configure it to run in a headful mode. All you need is Ruby and
[Chrome](https://www.google.com/chrome/) or
[Chromium](https://www.chromium.org/). Ferrum connects to the browser by [CDP
protocol](https://chromedevtools.github.io/devtools-protocol/) and  there's _no_
Selenium/WebDriver/ChromeDriver dependency. The emphasis was made on a raw CDP
protocol because Chrome allows you to do so many things that are barely
supported by WebDriver because it should have consistent design with other
browsers.

* [Cuprite](https://github.com/rubycdp/cuprite) is a pure Ruby driver for
[Capybara](https://github.com/teamcapybara/capybara) based on Ferrum. If you are
going to crawl sites you better use Ferrum or
[Vessel](https://github.com/rubycdp/vessel) because you crawl, not test.

* [Vessel](https://github.com/rubycdp/vessel) high-level web crawling framework
based on Ferrum and Mechanize.


## Index

* [Install](https://github.com/rubycdp/ferrum#install)
* [Examples](https://github.com/rubycdp/ferrum#examples)
* [Docker](https://github.com/rubycdp/ferrum#docker)
* [Customization](https://github.com/rubycdp/ferrum#customization)
* [Navigation](https://github.com/rubycdp/ferrum#navigation)
* [Finders](https://github.com/rubycdp/ferrum#finders)
* [Screenshots](https://github.com/rubycdp/ferrum#screenshots)
* [Cleaning Up](https://github.com/rubycdp/ferrum#cleaning-up)
* [Network](https://github.com/rubycdp/ferrum#network)
* [Proxy](https://github.com/rubycdp/ferrum#proxy)
* [Mouse](https://github.com/rubycdp/ferrum#mouse)
* [Keyboard](https://github.com/rubycdp/ferrum#keyboard)
* [Cookies](https://github.com/rubycdp/ferrum#cookies)
* [Headers](https://github.com/rubycdp/ferrum#headers)
* [JavaScript](https://github.com/rubycdp/ferrum#javascript)
* [Frames](https://github.com/rubycdp/ferrum#frames)
* [Frame](https://github.com/rubycdp/ferrum#frame)
* [Dialogs](https://github.com/rubycdp/ferrum#dialogs)
* [Animation](https://github.com/rubycdp/ferrum#animation)
* [Node](https://github.com/rubycdp/ferrum#node)
* [Tracing](https://github.com/rubycdp/ferrum#tracing)
* [Thread safety](https://github.com/rubycdp/ferrum#thread-safety)
* [Development](https://github.com/rubycdp/ferrum#development)
* [Contributing](https://github.com/rubycdp/ferrum#contributing)
* [License](https://github.com/rubycdp/ferrum#license)


## Install

There's no official Chrome or Chromium package for Linux don't install it this
way because it's either outdated or unofficial, both are bad. Download it from
official source for [Chrome](https://www.google.com/chrome/) or
[Chromium](https://www.chromium.org/getting-involved/download-chromium).
Chrome binary should be in the `PATH` or `BROWSER_PATH` or you can pass it as an
option to browser instance see `:browser_path` in
[Customization](https://github.com/rubycdp/ferrum#customization).

Add this to your `Gemfile` and run `bundle install`.

``` ruby
gem "ferrum"
```


## Examples

Navigate to a website and save a screenshot:

```ruby
browser = Ferrum::Browser.new
browser.go_to("https://google.com")
browser.screenshot(path: "google.png")
browser.quit
```

Interact with a page:

```ruby
browser = Ferrum::Browser.new
browser.go_to("https://google.com")
input = browser.at_xpath("//input[@name='q']")
input.focus.type("Ruby headless driver for Chrome", :Enter)
browser.at_css("a > h3").text # => "rubycdp/ferrum: Ruby Chrome/Chromium driver - GitHub"
browser.quit
```

Evaluate some JavaScript and get full width/height:

```ruby
browser = Ferrum::Browser.new
browser.go_to("https://www.google.com/search?q=Ruby+headless+driver+for+Capybara")
width, height = browser.evaluate <<~JS
  [document.documentElement.offsetWidth,
   document.documentElement.offsetHeight]
JS
# => [1024, 1931]
browser.quit
```

Do any mouse movements you like:

```ruby
# Trace a 100x100 square
browser = Ferrum::Browser.new
browser.go_to("https://google.com")
browser.mouse
  .move(x: 0, y: 0)
  .down
  .move(x: 0, y: 100)
  .move(x: 100, y: 100)
  .move(x: 100, y: 0)
  .move(x: 0, y: 0)
  .up

browser.quit
```


## Docker

In docker as root you must pass the no-sandbox browser option:

```ruby
Ferrum::Browser.new(browser_options: { 'no-sandbox': nil })
```

It has also been reported that the Chrome process repeatedly crashes when running inside a Docker container on an M1 Mac preventing Ferrum from working. Ferrum should work as expected when deployed to a Docker container on a non-M1 Mac.

## Customization

You can customize options with the following code in your test setup:

``` ruby
Ferrum::Browser.new(options)
```

* options `Hash`
  * `:headless` (String | Boolean) - Set browser as headless or not, `true` by default. You can set `"new"` to support
      [new headless mode](https://developer.chrome.com/articles/new-headless/).
  * `:xvfb` (Boolean) - Run browser in a virtual framebuffer, `false` by default.
  * `:window_size` (Array) - The dimensions of the browser window in which to
      test, expressed as a 2-element array, e.g. [1024, 768]. Default: [1024, 768]
  * `:extensions` (Array[String | Hash]) - An array of paths to files or JS
      source code to be preloaded into the browser e.g.:
      `["/path/to/script.js", { source: "window.secret = 'top'" }]`
  * `:logger` (Object responding to `puts`) - When present, debug output is
      written to this object.
  * `:slowmo` (Integer | Float) - Set a delay in seconds to wait before sending command.
      Useful companion of headless option, so that you have time to see changes.
  * `:timeout` (Numeric) - The number of seconds we'll wait for a response when
      communicating with browser. Default is 5.
  * `:js_errors` (Boolean) - When true, JavaScript errors get re-raised in Ruby.
  * `:pending_connection_errors` (Boolean) - When main frame is still waiting for slow responses while timeout is
      reached `PendingConnectionsError` is raised. It's better to figure out why you have slow responses and fix or
      block them rather than turn this setting off. Default is true.
  * `:browser_name` (Symbol) - `:chrome` by default, only experimental support
      for `:firefox` for now.
  * `:browser_path` (String) - Path to Chrome binary, you can also set ENV
      variable as `BROWSER_PATH=some/path/chrome bundle exec rspec`.
  * `:browser_options` (Hash) - Additional command line options,
      [see them all](https://peter.sh/experiments/chromium-command-line-switches/)
      e.g. `{ "ignore-certificate-errors" => nil }`
  * `:ignore_default_browser_options` (Boolean) - Ferrum has a number of default
      options it passes to the browser, if you set this to `true` then only
      options you put in `:browser_options` will be passed to the browser,
      except required ones of course.
  * `:port` (Integer) - Remote debugging port for headless Chrome.
  * `:host` (String) - Remote debugging address for headless Chrome.
  * `:url` (String) - URL for a running instance of Chrome. If this is set, a
      browser process will not be spawned.
  * `:process_timeout` (Integer) - How long to wait for the Chrome process to
      respond on startup.
  * `:ws_max_receive_size` (Integer) - How big messages to accept from Chrome
      over the web socket, in bytes. Defaults to 64MB. Incoming messages larger
      than this will cause a `Ferrum::DeadBrowserError`.
  * `:proxy` (Hash) - Specify proxy settings, [read more](https://github.com/rubycdp/ferrum#proxy)
  * `:save_path` (String) - Path to save attachments with [Content-Disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header.
  * `:env` (Hash) - Environment variables you'd like to pass through to the process


## Navigation

#### go_to(url) : `String`

Navigate page to.

  * url `String` The url should include scheme unless you set `base_url` when
  configuring driver.

```ruby
browser.go_to("https://github.com/")
```

#### back

Navigate to the previous page in history.

```ruby
browser.go_to("https://github.com/")
browser.at_xpath("//a").click
browser.back
```

#### forward

Navigate to the next page in history.

```ruby
browser.go_to("https://github.com/")
browser.at_xpath("//a").click
browser.back
browser.forward
```

#### refresh

Reload current page.

```ruby
browser.go_to("https://github.com/")
browser.refresh
```

#### stop

Stop all navigations and loading pending resources on the page

```ruby
browser.go_to("https://github.com/")
browser.stop
```

#### position = \*\*options

Set the position for the browser window

* options `Hash`
  * :left `Integer`
  * :top `Integer`

```ruby
browser.position = { left: 10, top: 20 }
```

#### position : `Array<Integer>`

Get the position for the browser window

```ruby
browser.position # => [10, 20]
```

## Finders

#### at_css(selector, \*\*options) : `Node` | `nil`

Find node by selector. Runs `document.querySelector` within the document or
provided node.

  * selector `String`
  * options `Hash`
    * :within `Node` | `nil`

```ruby
browser.go_to("https://github.com/")
browser.at_css("a[aria-label='Issues you created']") # => Node
```


#### css(selector, \*\*options) : `Array<Node>` | `[]`

Find nodes by selector. The method runs `document.querySelectorAll` within the
document or provided node.

* selector `String`
* options `Hash`
  * :within `Node` | `nil`

```ruby
browser.go_to("https://github.com/")
browser.css("a[aria-label='Issues you created']") # => [Node]
```

#### at_xpath(selector, \*\*options) : `Node` | `nil`

Find node by xpath.

* selector `String`
* options `Hash`
  * :within `Node` | `nil`

```ruby
browser.go_to("https://github.com/")
browser.at_xpath("//a[@aria-label='Issues you created']") # => Node
```

#### xpath(selector, \*\*options) : `Array<Node>` | `[]`

Find nodes by xpath.

* selector `String`
* options `Hash`
  * :within `Node` | `nil`

```ruby
browser.go_to("https://github.com/")
browser.xpath("//a[@aria-label='Issues you created']") # => [Node]
```

#### current_url : `String`

Returns current top window location href.

```ruby
browser.go_to("https://google.com/")
browser.current_url # => "https://www.google.com/"
```

#### current_title : `String`

Returns current top window title

```ruby
browser.go_to("https://google.com/")
browser.current_title # => "Google"
```

#### body : `String`

Returns current page's html.

```ruby
browser.go_to("https://google.com/")
browser.body # => '<html itemscope="" itemtype="http://schema.org/WebPage" lang="ru"><head>...
```


## Screenshots

#### screenshot(\*\*options) : `String` | `Integer`

Saves screenshot on a disk or returns it as base64.

* options `Hash`
  * :path `String` to save a screenshot on the disk. `:encoding` will be set to
    `:binary` automatically
  * :encoding `Symbol` `:base64` | `:binary` you can set it to return image as
    Base64
  * :format `String` "jpeg" | "png"
  * :quality `Integer` 0-100 works for jpeg only
  * :full `Boolean` whether you need full page screenshot or a viewport
  * :selector `String` css selector for given element
  * :scale `Float` zoom in/out
  * :background_color `Ferrum::RGBA.new(0, 0, 0, 0.0)` to have specific background color

```ruby
browser.go_to("https://google.com/")
# Save on the disk in PNG
browser.screenshot(path: "google.png") # => 134660
# Save on the disk in JPG
browser.screenshot(path: "google.jpg") # => 30902
# Save to Base64 the whole page not only viewport and reduce quality
browser.screenshot(full: true, quality: 60) # "iVBORw0KGgoAAAANSUhEUgAABAAAAAMACAYAAAC6uhUNAAAAAXNSR0IArs4c6Q...
# Save with specific background color
browser.screenshot(background_color: Ferrum::RGBA.new(0, 0, 0, 0.0))
```

#### pdf(\*\*options) : `String` | `Boolean`

Saves PDF on a disk or returns it as base64.

* options `Hash`
  * :path `String` to save a pdf on the disk. `:encoding` will be set to
    `:binary` automatically
  * :encoding `Symbol` `:base64` | `:binary` you can set it to return pdf as
    Base64
  * :landscape `Boolean` paper orientation. Defaults to false.
  * :scale `Float` zoom in/out
  * :format `symbol` standard paper sizes :letter, :legal, :tabloid, :ledger, :A0, :A1, :A2, :A3, :A4, :A5, :A6

  * :paper_width `Float` set paper width
  * :paper_height `Float` set paper height
  * See other [native options](https://chromedevtools.github.io/devtools-protocol/tot/Page#method-printToPDF) you can pass

```ruby
browser.go_to("https://google.com/")
# Save to disk as a PDF
browser.pdf(path: "google.pdf", paper_width: 1.0, paper_height: 1.0) # => true
```

#### mhtml(\*\*options) : `String` | `Integer`

Saves MHTML on a disk or returns it as a string.

* options `Hash`
  * :path `String` to save a file on the disk.

```ruby
browser.go_to("https://google.com/")
browser.mhtml(path: "google.mhtml") # => 87742
```


## Cleaning Up

#### reset

Closes browser tabs opened by the `Browser` instance.

```ruby
# connect to a long-running Chrome process
browser = Ferrum::Browser.new(url: 'http://localhost:9222')

browser.go_to("https://github.com/")

# clean up, lest the tab stays there hanging forever
browser.reset

browser.quit
```


## Network

`browser.network`

#### traffic `Array<Network::Exchange>`

Returns all information about network traffic as `Network::Exchange` instance
which in general is a wrapper around `request`, `response` and `error`.

```ruby
browser.go_to("https://github.com/")
browser.network.traffic # => [#<Ferrum::Network::Exchange, ...]
```

#### request : `Network::Request`

Page request of the main frame.

```ruby
browser.go_to("https://github.com/")
browser.network.request # => #<Ferrum::Network::Request...
```

#### response : `Network::Response`

Page response of the main frame.

```ruby
browser.go_to("https://github.com/")
browser.network.response # => #<Ferrum::Network::Response...
```

#### status : `Integer`

Contains the status code of the main page response (e.g., 200 for a
success). This is just a shortcut for `response.status`.

```ruby
browser.go_to("https://github.com/")
browser.network.status # => 200
```

#### wait_for_idle(\*\*options)

Waits for network idle or raises `Ferrum::TimeoutError` error

* options `Hash`
  * :connections `Integer` how many connections are allowed for network to be
    idling, `0` by default
  * :duration `Float` sleep for given amount of time and check again, `0.05` by
    default
  * :timeout `Float` during what time we try to check idle, `browser.timeout`
    by default

```ruby
browser.go_to("https://example.com/")
browser.at_xpath("//a[text() = 'No UI changes button']").click
browser.network.wait_for_idle
```

#### clear(type)

Clear browser's cache or collected traffic.

* type `Symbol` it is either `:traffic` or `:cache`

```ruby
traffic = browser.network.traffic # => []
browser.go_to("https://github.com/")
traffic.size # => 51
browser.network.clear(:traffic)
traffic.size # => 0
```

#### intercept(\*\*options)

Set request interception for given options. This method is only sets request
interception, you should use `on` callback to catch requests and abort or
continue them.

* options `Hash`
  * :pattern `String` \* by default
  * :resource_type `Symbol` one of the [resource types](https://chromedevtools.github.io/devtools-protocol/tot/Network#type-ResourceType)

```ruby
browser = Ferrum::Browser.new
browser.network.intercept
browser.on(:request) do |request|
  if request.match?(/bla-bla/)
    request.abort
  elsif request.match?(/lorem/)
    request.respond(body: "Lorem ipsum")
  else
    request.continue
  end
end
browser.go_to("https://google.com")
```

#### authorize(\*\*options, &block)

If site or proxy uses authorization you can provide credentials using this method.

* options `Hash`
  * :type `Symbol` `:server` | `:proxy` site or proxy authorization
  * :user `String`
  * :password `String`
* &block accepts authenticated request, which you must subsequently allow or deny, if you don't
care about unwanted requests just call `request.continue`.

```ruby
browser.network.authorize(user: "login", password: "pass") { |req| req.continue }
browser.go_to("http://example.com/authenticated")
puts browser.network.status # => 200
puts browser.body # => Welcome, authenticated client
```

Since Chrome implements authorize using request interception you must continue or abort authorized requests. If you
already have code that uses interception you can use `authorize` without block, but if not you are obliged to pass
block, so this is version doesn't pass block and can work just fine:

```ruby
browser = Ferrum::Browser.new
browser.network.intercept
browser.on(:request) do |request|
  if request.resource_type == "Image"
    request.abort
  else
    request.continue
  end
end

browser.network.authorize(user: "login", password: "pass", type: :proxy)

browser.go_to("https://google.com")
```

You used to call `authorize` method without block, but since it's implemented using request interception there could be
a collision with another part of your code that also uses request interception, so that authorize allows the request
while your code denies but it's too late. The block is mandatory now.

#### emulate_network_conditions(\*\*options)

Activates emulation of network conditions.

* options `Hash`
  * :offline `Boolean` emulate internet disconnection, `false` by default
  * :latency `Integer` minimum latency from request sent to response headers received (ms), `0` by
    default
  * :download_throughput `Integer` maximal aggregated download throughput (bytes/sec), `-1`
    by default, disables download throttling
  * :upload_throughput `Integer` maximal aggregated upload throughput (bytes/sec), `-1`
    by default, disables download throttling
  * :connection_type `String` connection type if known, one of: none, cellular2g, cellular3g, cellular4g,
    bluetooth, ethernet, wifi, wimax, other. `nil` by default

```ruby
browser.network.emulate_network_conditions(connection_type: "cellular2g")
browser.go_to("https://github.com/")
```

#### offline_mode

Activates offline mode for a page.

```ruby
browser.network.offline_mode
browser.go_to("https://github.com/") # => Ferrum::StatusError (Request to https://github.com/ failed(net::ERR_INTERNET_DISCONNECTED))
```

#### cache(disable: `Boolean`)

Toggles ignoring cache for each request. If true, cache will not be used.

```ruby
browser.network.cache(disable: true)
```

## Proxy

You can set a proxy with a `:proxy` option:

```ruby
browser = Ferrum::Browser.new(proxy: { host: "x.x.x.x", port: "8800", user: "user", password: "pa$$" })
```

`:bypass` can specify semi-colon-separated list of hosts for which proxy shouldn't be used:

```ruby
browser = Ferrum::Browser.new(proxy: { host: "x.x.x.x", port: "8800", bypass: "*.google.com;*foo.com" })
```

In general passing a proxy option when instantiating a browser results in a browser running with proxy command line
flags, so that it affects all pages and contexts. You can create a page in a new context which can use its own proxy
settings:

```ruby
browser = Ferrum::Browser.new

browser.create_page(proxy: { host: "x.x.x.x", port: 31337, user: "user", password: "password" }) do |page|
  page.go_to("https://api.ipify.org?format=json")
  page.body # => "x.x.x.x"
end

browser.create_page(proxy: { host: "y.y.y.y", port: 31337, user: "user", password: "password" }) do |page|
  page.go_to("https://api.ipify.org?format=json")
  page.body # => "y.y.y.y"
end
```


### Mouse

`browser.mouse`

#### scroll_to(x, y)

Scroll page to a given x, y

  * x `Integer` the pixel along the horizontal axis of the document that you
  want displayed in the upper left
  * y `Integer` the pixel along the vertical axis of the document that you want
  displayed in the upper left

```ruby
browser.go_to("https://www.google.com/search?q=Ruby+headless+driver+for+Capybara")
browser.mouse.scroll_to(0, 400)
```

#### click(\*\*options) : `Mouse`

Click given coordinates, fires mouse move, down and up events.

* options `Hash`
  * :x `Integer`
  * :y `Integer`
  * :delay `Float` defaults to 0. Delay between mouse down and mouse up events
  * :button `Symbol` :left | :right, defaults to :left
  * :count `Integer` defaults to 1
  * :modifiers `Integer` bitfield for key modifiers. See`keyboard.modifiers`

#### down(\*\*options) : `Mouse`

Mouse down for given coordinates.

* options `Hash`
  * :button `Symbol` :left | :right, defaults to :left
  * :count `Integer` defaults to 1
  * :modifiers `Integer` bitfield for key modifiers. See`keyboard.modifiers`

#### up(\*\*options) : `Mouse`

Mouse up for given coordinates.

* options `Hash`
  * :button `Symbol` :left | :right, defaults to :left
  * :count `Integer` defaults to 1
  * :modifiers `Integer` bitfield for key modifiers. See`keyboard.modifiers`

#### move(x:, y:, steps: 1) : `Mouse`

Mouse move to given x and y.

* options `Hash`
  * :x `Integer`
  * :y `Integer`
  * :steps `Integer` defaults to 1. Sends intermediate mousemove events.

### Keyboard

browser.keyboard

#### down(key) : `Keyboard`

Dispatches a keydown event.

* key `String` | `Symbol` Name of key such as "a", :enter, :backspace

#### up(key) : `Keyboard`

Dispatches a keyup event.

* key `String` | `Symbol` Name of key such as "b", :enter, :backspace

#### type(\*keys) : `Keyboard`

Sends a keydown, keypress/input, and keyup event for each character in the text.

* text `String` | `Array<String> | Array<Symbol>` A text to type into a focused
  element, `[:Shift, "s"], "tring"`

#### modifiers(keys) : `Integer`

Returns bitfield for a given keys

* keys `Array<Symbol>` :alt | :ctrl | :command | :shift


## Cookies

`browser.cookies`

#### all : `Hash<String, Cookie>`

Returns cookies hash

```ruby
browser.cookies.all # => {"NID"=>#<Ferrum::Cookies::Cookie:0x0000558624b37a40 @attributes={"name"=>"NID", "value"=>"...", "domain"=>".google.com", "path"=>"/", "expires"=>1583211046.575681, "size"=>178, "httpOnly"=>true, "secure"=>false, "session"=>false}>}
```

#### [](value) : `Cookie`

Returns cookie

* value `String`

```ruby
browser.cookies["NID"] # => <Ferrum::Cookies::Cookie:0x0000558624b67a88 @attributes={"name"=>"NID", "value"=>"...", "domain"=>".google.com", "path"=>"/", "expires"=>1583211046.575681, "size"=>178, "httpOnly"=>true, "secure"=>false, "session"=>false}>
```

#### set(value) : `Boolean`

Sets a cookie

* value `Hash`
  * :name `String`
  * :value `String`
  * :domain `String`
  * :expires `Integer`
  * :samesite `String`
  * :httponly `Boolean`

```ruby
browser.cookies.set(name: "stealth", value: "omg", domain: "google.com") # => true
```

* value `Cookie`

```ruby
nid_cookie = browser.cookies["NID"] # => <Ferrum::Cookies::Cookie:0x0000558624b67a88>
browser.cookies.set(nid_cookie) # => true
```

#### remove(\*\*options) : `Boolean`

Removes given cookie

* options `Hash`
  * :name `String`
  * :domain `String`
  * :url `String`

```ruby
browser.cookies.remove(name: "stealth", domain: "google.com") # => true
```

#### clear : `Boolean`

Removes all cookies for current page

```ruby
browser.cookies.clear # => true
```

## Headers

`browser.headers`

#### get : `Hash`

Get all headers

#### set(headers) : `Boolean`

Set given headers. Eventually clear all headers and set given ones.

* headers `Hash` key-value pairs for example `"User-Agent" => "Browser"`

#### add(headers) : `Boolean`

Adds given headers to already set ones.

* headers `Hash` key-value pairs for example `"Referer" => "http://example.com"`

#### clear : `Boolean`

Clear all headers.


## JavaScript

#### evaluate(expression, \*args)

Evaluate and return result for given JS expression

* expression `String` should be valid JavaScript
* args `Object` you can pass arguments, though it should be a valid `Node` or a
simple value.

```ruby
browser.evaluate("[window.scrollX, window.scrollY]")
```

#### evaluate_async(expression, wait_time, \*args)

Evaluate asynchronous expression and return result

* expression `String` should be valid JavaScript
* wait_time How long we should wait for Promise to resolve or reject
* args `Object` you can pass arguments, though it should be a valid `Node` or a
simple value.

```ruby
browser.evaluate_async(%(arguments[0]({foo: "bar"})), 5) # => { "foo" => "bar" }
```

#### execute(expression, \*args)

Execute expression. Doesn't return the result

* expression `String` should be valid JavaScript
* args `Object` you can pass arguments, though it should be a valid `Node` or a
simple value.

```ruby
browser.execute(%(1 + 1)) # => true
```

#### evaluate_on_new_document(expression)

Evaluate JavaScript to modify things before a page load

* expression `String` should be valid JavaScript

```ruby
browser.evaluate_on_new_document <<~JS
  Object.defineProperty(navigator, "languages", {
    get: function() { return ["tlh"]; }
  });
JS
```

#### add_script_tag(\*\*options) : `Boolean`

* options `Hash`
  * :url `String`
  * :path `String`
  * :content `String`
  * :type `String` - `text/javascript` by default

```ruby
browser.add_script_tag(url: "http://example.com/stylesheet.css") # => true
```

#### add_style_tag(\*\*options) : `Boolean`

* options `Hash`
  * :url `String`
  * :path `String`
  * :content `String`

```ruby
browser.add_style_tag(content: "h1 { font-size: 40px; }") # => true

```
#### bypass_csp(\*\*options) : `Boolean`

* options `Hash`
  * :enabled `Boolean`, `true` by default

```ruby
browser.bypass_csp # => true
browser.go_to("https://github.com/ruby-concurrency/concurrent-ruby/blob/master/docs-source/promises.in.md")
browser.refresh
browser.add_script_tag(content: "window.__injected = 42")
browser.evaluate("window.__injected") # => 42
```


## Frames

#### frames : `Array[Frame] | []`

Returns all the frames current page have.

```ruby
browser.go_to("https://www.w3schools.com/tags/tag_frame.asp")
browser.frames # =>
# [
#   #<Ferrum::Frame @id="C6D104CE454A025FBCF22B98DE612B12" @parent_id=nil @name=nil @state=:stopped_loading @execution_id=1>,
#   #<Ferrum::Frame @id="C09C4E4404314AAEAE85928EAC109A93" @parent_id="C6D104CE454A025FBCF22B98DE612B12" @state=:stopped_loading @execution_id=2>,
#   #<Ferrum::Frame @id="2E9C7F476ED09D87A42F2FEE3C6FBC3C" @parent_id="C6D104CE454A025FBCF22B98DE612B12" @state=:stopped_loading @execution_id=3>,
#   ...
# ]
```

#### main_frame : `Frame`

Returns page's main frame, the top of the tree and the parent of all frames.

#### frame_by(\*\*options) : `Frame | nil`

Find frame by given options.

* options `Hash`
  * :id `String` - Unique frame's id that browser provides
  * :name `String` - Frame's name if there's one

```ruby
browser.frame_by(id: "C6D104CE454A025FBCF22B98DE612B12")
```


## Frame

#### id : `String`

Frame's unique id.

#### parent_id : `String | nil`

Parent frame id if this one is nested in another one.

#### execution_id : `Integer`

Execution context id which is used by JS, each frame has it's own context in
which JS evaluates.

#### name : `String | nil`

If frame was given a name it should be here.

#### state : `Symbol | nil`

One of the states frame's in:

* `:started_loading`
* `:navigated`
* `:stopped_loading`

#### url : `String`

Returns current frame's location href.

```ruby
browser.go_to("https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe")
frame = browser.frames[1]
frame.url # => https://interactive-examples.mdn.mozilla.net/pages/tabbed/iframe.html
```

#### title

Returns current frame's title.

```ruby
browser.go_to("https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe")
frame = browser.frames[1]
frame.title # => HTML Demo: <iframe>
```

#### main? : `Boolean`

If current frame is the main frame of the page (top of the tree).

```ruby
browser.go_to("https://www.w3schools.com/tags/tag_frame.asp")
frame = browser.frame_by(id: "C09C4E4404314AAEAE85928EAC109A93")
frame.main? # => false
```

#### current_url : `String`

Returns current frame's top window location href.

```ruby
browser.go_to("https://www.w3schools.com/tags/tag_frame.asp")
frame = browser.frame_by(id: "C09C4E4404314AAEAE85928EAC109A93")
frame.current_url # => "https://www.w3schools.com/tags/tag_frame.asp"
```

#### current_title : `String`

Returns current frame's top window title.

```ruby
browser.go_to("https://www.w3schools.com/tags/tag_frame.asp")
frame = browser.frame_by(id: "C09C4E4404314AAEAE85928EAC109A93")
frame.current_title # => "HTML frame tag"
```

#### body : `String`

Returns current frame's html.

```ruby
browser.go_to("https://www.w3schools.com/tags/tag_frame.asp")
frame = browser.frame_by(id: "C09C4E4404314AAEAE85928EAC109A93")
frame.body # => "<html><head></head><body></body></html>"
```

#### doctype

Returns current frame's doctype.

```ruby
browser.go_to("https://www.w3schools.com/tags/tag_frame.asp")
browser.main_frame.doctype # => "<!DOCTYPE html>"
```

#### content = html

Sets a content of a given frame.

  * html `String`

```ruby
browser.go_to("https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe")
frame = browser.frames[1]
frame.body # <html lang="en"><head><style>body {transition: opacity ease-in 0.2s; }...
frame.content = "<html><head></head><body><p>lol</p></body></html>"
frame.body # => <html><head></head><body><p>lol</p></body></html>
```


## Dialogs

#### accept(text)

Accept dialog with given text or default prompt if applicable

  * text `String`

#### dismiss

Dismiss dialog

```ruby
browser = Ferrum::Browser.new
browser.on(:dialog) do |dialog|
  if dialog.match?(/bla-bla/)
    dialog.accept
  else
    dialog.dismiss
  end
end
browser.go_to("https://google.com")
```


## Animation

You can slow down or speed up CSS animations.

#### playback_rate : `Integer`

Returns playback rate for CSS animations, defaults to `1`.


#### playback_rate = value

Sets playback rate of CSS animations

  * value `Integer`

```ruby
browser = Ferrum::Browser.new
browser.playback_rate = 2000
browser.go_to("https://google.com")
browser.playback_rate # => 2000
```


## Node

#### node? : `Boolean`
#### frame_id
#### frame  : `Frame`

Returns [Frame](https://github.com/rubycdp/ferrum#frame) object for current node, you can keep using
[Finders](https://github.com/rubycdp/ferrum#Finders) for that object:

```ruby
frame =  browser.at_xpath("//iframe").frame # => Frame
frame.at_css("//a[text() = 'Log in']") # => Node
```

#### focus
#### focusable?
#### moving? : `Boolean`
#### wait_for_stop_moving
#### blur
#### type
#### click
#### hover
#### select_file
#### at_xpath
#### at_css
#### xpath
#### css
#### text
#### inner_text
#### value
#### property
#### attribute
#### evaluate
#### selected : `Array<Node>`
#### select
#### scroll_into_view
#### in_viewport?(of: `Node | nil`) : `Boolean`

(chainable) Selects options by passed attribute.

```ruby
browser.at_xpath("//*[select]").select(["1"]) # => Node (select)
browser.at_xpath("//*[select]").select(["text"], by: :text) # => Node (select)
```

Accept string, array or strings:
```ruby
browser.at_xpath("//*[select]").select("1")
browser.at_xpath("//*[select]").select("1", "2")
browser.at_xpath("//*[select]").select(["1", "2"])
```


## Tracing

You can use `tracing.record` to create a trace file which can be opened in Chrome DevTools or
[timeline viewer](https://chromedevtools.github.io/timeline-viewer/).

```ruby
page.tracing.record(path: "trace.json") do
  page.go_to("https://www.google.com")
end
```

#### tracing.record(\*\*options) : `String`

Accepts block, records trace and by default returns trace data from `Tracing.tracingComplete` event as output. When
`path` is specified returns `true` and stores trace data into file.

* options `Hash`
  * :path `String` save data on the disk, `nil` by default
  * :encoding `Symbol` `:base64` | `:binary` encode output as Base64 or plain text. `:binary` by default
  * :timeout `Float` wait until file streaming finishes in the specified time or raise error, defaults to `nil`
  * :screenshots `Boolean` capture screenshots in the trace, `false` by default
  * :trace_config `Hash<String, Object>` config for
    [trace](https://chromedevtools.github.io/devtools-protocol/tot/Tracing/#type-TraceConfig), for categories
    see [getCategories](https://chromedevtools.github.io/devtools-protocol/tot/Tracing/#method-getCategories),
    only one trace config can be active at a time per browser.


## Thread safety ##

Ferrum is fully thread-safe. You can create one browser or a few as you wish and
start playing around using threads. Example below shows how to create a few pages
which share the same context. Context is similar to an incognito profile but you
can have more than one, think of it like it's independent browser session:

```ruby
browser = Ferrum::Browser.new
context = browser.contexts.create

t1 = Thread.new(context) do |c|
  page = c.create_page
  page.go_to("https://www.google.com/search?q=Ruby+headless+driver+for+Capybara")
  page.screenshot(path: "t1.png")
end

t2 = Thread.new(context) do |c|
  page = c.create_page
  page.go_to("https://www.google.com/search?q=Ruby+static+typing")
  page.screenshot(path: "t2.png")
end

t1.join
t2.join

context.dispose
browser.quit
```

or you can create two independent contexts:

```ruby
browser = Ferrum::Browser.new

t1 = Thread.new(browser) do |b|
  context = b.contexts.create
  page = context.create_page
  page.go_to("https://www.google.com/search?q=Ruby+headless+driver+for+Capybara")
  page.screenshot(path: "t1.png")
  context.dispose
end

t2 = Thread.new(browser) do |b|
  context = b.contexts.create
  page = context.create_page
  page.go_to("https://www.google.com/search?q=Ruby+static+typing")
  page.screenshot(path: "t2.png")
  context.dispose
end

t1.join
t2.join

browser.quit
```

## Development

After checking out the repo, run `bundle install` to install dependencies.

Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will
allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/rubycdp/ferrum).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
