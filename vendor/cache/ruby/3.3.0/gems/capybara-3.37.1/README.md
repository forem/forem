# Capybara

[![Build Status](https://secure.travis-ci.org/teamcapybara/capybara.svg)](https://travis-ci.org/teamcapybara/capybara)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/teamcapybara/capybara?svg=true)](https://ci.appveyor.com/api/projects/github/teamcapybara/capybara)
[![Code Climate](https://codeclimate.com/github/teamcapybara/capybara.svg)](https://codeclimate.com/github/teamcapybara/capybara)
[![Coverage Status](https://coveralls.io/repos/github/teamcapybara/capybara/badge.svg?branch=master)](https://coveralls.io/github/teamcapybara/capybara?branch=master)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jnicklas/capybara?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![SemVer](https://api.dependabot.com/badges/compatibility_score?dependency-name=capybara&package-manager=bundler&version-scheme=semver)](https://dependabot.com/compatibility-score.html?dependency-name=capybara&package-manager=bundler&version-scheme=semver)

Capybara helps you test web applications by simulating how a real user would
interact with your app. It is agnostic about the driver running your tests and
comes with Rack::Test and Selenium support built in. WebKit is supported
through an external gem.

## Support Capybara

If you and/or your company find value in Capybara and would like to contribute financially to its ongoing maintenance and development, please visit
<a href="https://www.patreon.com/capybara">Patreon</a>


**Need help?** Ask on the mailing list (please do not open an issue on
GitHub): http://groups.google.com/group/ruby-capybara

## Table of contents

- [Key benefits](#key-benefits)
- [Setup](#setup)
- [Using Capybara with Cucumber](#using-capybara-with-cucumber)
- [Using Capybara with RSpec](#using-capybara-with-rspec)
- [Using Capybara with Test::Unit](#using-capybara-with-testunit)
- [Using Capybara with Minitest](#using-capybara-with-minitest)
- [Using Capybara with Minitest::Spec](#using-capybara-with-minitestspec)
- [Drivers](#drivers)
    - [Selecting the Driver](#selecting-the-driver)
    - [RackTest](#racktest)
    - [Selenium](#selenium)
    - [Apparition](#apparition)
- [The DSL](#the-dsl)
    - [Navigating](#navigating)
    - [Clicking links and buttons](#clicking-links-and-buttons)
    - [Interacting with forms](#interacting-with-forms)
    - [Querying](#querying)
    - [Finding](#finding)
    - [Scoping](#scoping)
    - [Working with windows](#working-with-windows)
    - [Scripting](#scripting)
    - [Modals](#modals)
    - [Debugging](#debugging)
- [Matching](#matching)
    - [Exactness](#exactness)
    - [Strategy](#strategy)
- [Transactions and database setup](#transactions-and-database-setup)
- [Asynchronous JavaScript (Ajax and friends)](#asynchronous-javascript-ajax-and-friends)
- [Using the DSL elsewhere](#using-the-dsl-elsewhere)
- [Calling remote servers](#calling-remote-servers)
- [Using sessions](#using-sessions)
    - [Named sessions](#named-sessions)
    - [Using sessions manually](#using-sessions-manually)
- [XPath, CSS and selectors](#xpath-css-and-selectors)
- [Beware the XPath // trap](#beware-the-xpath--trap)
- [Configuring and adding drivers](#configuring-and-adding-drivers)
- [Gotchas:](#gotchas)
- ["Threadsafe" mode](#threadsafe-mode)
- [Development](#development)

## <a name="key-benefits"></a>Key benefits

- **No setup** necessary for Rails and Rack application. Works out of the box.
- **Intuitive API** which mimics the language an actual user would use.
- **Switch the backend** your tests run against from fast headless mode
  to an actual browser with no changes to your tests.
- **Powerful synchronization** features mean you never have to manually wait
  for asynchronous processes to complete.

## <a name="setup"></a>Setup

Capybara requires Ruby 2.7.0 or later. To install, add this line to your
`Gemfile` and run `bundle install`:

```ruby
gem 'capybara'
```

If the application that you are testing is a Rails app, add this line to your test helper file:

```ruby
require 'capybara/rails'
```

If the application that you are testing is a Rack app, but not Rails, set Capybara.app to your Rack app:

```ruby
Capybara.app = MyRackApp
```

If you need to test JavaScript, or if your app interacts with (or is located at)
a remote URL, you'll need to [use a different driver](#drivers).  If using Rails 5.0+, but not using the Rails system tests from 5.1, you'll probably also
want to swap the "server" used to launch your app to Puma in order to match Rails defaults.

```ruby
Capybara.server = :puma # Until your setup is working
Capybara.server = :puma, { Silent: true } # To clean up your test output
```

## <a name="using-capybara-with-cucumber"></a>Using Capybara with Cucumber

The `cucumber-rails` gem comes with Capybara support built-in. If you
are not using Rails, manually load the `capybara/cucumber` module:

```ruby
require 'capybara/cucumber'
Capybara.app = MyRackApp
```

You can use the Capybara DSL in your steps, like so:

```ruby
When /I sign in/ do
  within("#session") do
    fill_in 'Email', with: 'user@example.com'
    fill_in 'Password', with: 'password'
  end
  click_button 'Sign in'
end
```

You can switch to the `Capybara.javascript_driver` (`:selenium`
by default) by tagging scenarios (or features) with `@javascript`:

```ruby
@javascript
Scenario: do something Ajaxy
  When I click the Ajax link
  ...
```

There are also explicit tags for each registered driver set up for you (`@selenium`, `@rack_test`, etc).

## <a name="using-capybara-with-rspec"></a>Using Capybara with RSpec

Load RSpec 3.5+ support by adding the following line (typically to your
`spec_helper.rb` file):

```ruby
require 'capybara/rspec'
```

If you are using Rails, put your Capybara specs in `spec/features` or `spec/system` (only works
if [you have it configured in
RSpec](https://relishapp.com/rspec/rspec-rails/v/4-0/docs/directory-structure))
and if you have your Capybara specs in a different directory, then tag the
example groups with `type: :feature` or `type: :system` depending on which type of test you're writing.

If you are using Rails system specs please see [their documentation](https://relishapp.com/rspec/rspec-rails/docs/system-specs/system-spec#system-specs-driven-by-selenium-chrome-headless) for selecting the driver you wish to use.

If you are not using Rails, tag all the example groups in which you want to use
Capybara with `type: :feature`.

You can now write your specs like so:

```ruby
describe "the signin process", type: :feature do
  before :each do
    User.make(email: 'user@example.com', password: 'password')
  end

  it "signs me in" do
    visit '/sessions/new'
    within("#session") do
      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password'
    end
    click_button 'Sign in'
    expect(page).to have_content 'Success'
  end
end
```

Use `js: true` to switch to the `Capybara.javascript_driver`
(`:selenium` by default), or provide a `:driver` option to switch
to one specific driver. For example:

```ruby
describe 'some stuff which requires js', js: true do
  it 'will use the default js driver'
  it 'will switch to one specific driver', driver: :apparition
end
```

Capybara also comes with a built in DSL for creating descriptive acceptance tests:

```ruby
feature "Signing in" do
  background do
    User.make(email: 'user@example.com', password: 'caplin')
  end

  scenario "Signing in with correct credentials" do
    visit '/sessions/new'
    within("#session") do
      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'caplin'
    end
    click_button 'Sign in'
    expect(page).to have_content 'Success'
  end

  given(:other_user) { User.make(email: 'other@example.com', password: 'rous') }

  scenario "Signing in as another user" do
    visit '/sessions/new'
    within("#session") do
      fill_in 'Email', with: other_user.email
      fill_in 'Password', with: other_user.password
    end
    click_button 'Sign in'
    expect(page).to have_content 'Invalid email or password'
  end
end
```

`feature` is in fact just an alias for `describe ..., type: :feature`,
`background` is an alias for `before`, `scenario` for `it`, and
`given`/`given!` aliases for `let`/`let!`, respectively.

Finally, Capybara matchers are also supported in view specs:

```ruby
RSpec.describe "todos/show.html.erb", type: :view do
  it "displays the todo title" do
    assign :todo, Todo.new(title: "Buy milk")

    render

    expect(rendered).to have_css("header h1", text: "Buy milk")
  end
end
```

**Note: When you require 'capybara/rspec' proxy methods are installed to work around name collisions between Capybara::DSL methods
  `all`/`within` and the identically named built-in RSpec matchers. If you opt not to require 'capybara/rspec' you can install the proxy methods by requiring 'capybara/rspec/matcher_proxies' after requiring RSpec and 'capybara/dsl'**

## <a name="using-capybara-with-testunit"></a>Using Capybara with Test::Unit

* If you are using `Test::Unit`, define a base class for your Capybara tests
  like so:

    ```ruby
    require 'capybara/dsl'

    class CapybaraTestCase < Test::Unit::TestCase
      include Capybara::DSL

      def teardown
        Capybara.reset_sessions!
        Capybara.use_default_driver
      end
    end
    ```

## <a name="using-capybara-with-minitest"></a>Using Capybara with Minitest

* If you are using Rails system tests please see their documentation for information on selecting the driver you wish to use.

* If you are using Rails, but not using Rails system tests, add the following code in your `test_helper.rb`
    file to make Capybara available in all test cases deriving from
    `ActionDispatch::IntegrationTest`:

    ```ruby
    require 'capybara/rails'
    require 'capybara/minitest'

    class ActionDispatch::IntegrationTest
      # Make the Capybara DSL available in all integration tests
      include Capybara::DSL
      # Make `assert_*` methods behave like Minitest assertions
      include Capybara::Minitest::Assertions

      # Reset sessions and driver between tests
      teardown do
        Capybara.reset_sessions!
        Capybara.use_default_driver
      end
    end
    ```

* If you are not using Rails, define a base class for your Capybara tests like
  so:

    ```ruby
    require 'capybara/minitest'

    class CapybaraTestCase < Minitest::Test
      include Capybara::DSL
      include Capybara::Minitest::Assertions

      def teardown
        Capybara.reset_sessions!
        Capybara.use_default_driver
      end
    end
    ```

    Remember to call `super` in any subclasses that override
    `teardown`.

To switch the driver, set `Capybara.current_driver`. For instance,

```ruby
class BlogTest < ActionDispatch::IntegrationTest
  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
  end

  test 'shows blog posts' do
    # ... this test is run with Selenium ...
  end
end
```

## <a name="using-capybara-with-minitestspec"></a>Using Capybara with Minitest::Spec

Follow the above instructions for Minitest and additionally require capybara/minitest/spec

```ruby
page.must_have_content('Important!')
```

## <a name="drivers"></a>Drivers

Capybara uses the same DSL to drive a variety of browser and headless drivers.

### <a name="selecting-the-driver"></a>Selecting the Driver

By default, Capybara uses the `:rack_test` driver, which is fast but limited: it
does not support JavaScript, nor is it able to access HTTP resources outside of
your Rack application, such as remote APIs and OAuth services. To get around
these limitations, you can set up a different default driver for your features.
For example if you'd prefer to run everything in Selenium, you could do:

```ruby
Capybara.default_driver = :selenium # :selenium_chrome and :selenium_chrome_headless are also registered
```

However, if you are using RSpec or Cucumber (and your app runs correctly without JS),
you may instead want to consider leaving the faster `:rack_test` as the __default_driver__, and
marking only those tests that require a JavaScript-capable driver using `js: true` or
`@javascript`, respectively.  By default, JavaScript tests are run using the
`:selenium` driver. You can change this by setting
`Capybara.javascript_driver`.

You can also change the driver temporarily (typically in the Before/setup and
After/teardown blocks):

```ruby
Capybara.current_driver = :apparition # temporarily select different driver
# tests here
Capybara.use_default_driver       # switch back to default driver
```

**Note**: switching the driver creates a new session, so you may not be able to
switch in the middle of a test.

### <a name="racktest"></a>RackTest

RackTest is Capybara's default driver. It is written in pure Ruby and does not
have any support for executing JavaScript. Since the RackTest driver interacts
directly with Rack interfaces, it does not require a server to be started.
However, this means that if your application is not a Rack application (Rails,
Sinatra and most other Ruby frameworks are Rack applications) then you cannot
use this driver. Furthermore, you cannot use the RackTest driver to test a
remote application, or to access remote URLs (e.g., redirects to external
sites, external APIs, or OAuth services) that your application might interact
with.

[capybara-mechanize](https://github.com/jeroenvandijk/capybara-mechanize)
provides a similar driver that can access remote servers.

RackTest can be configured with a set of headers like this:

```ruby
Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, headers: { 'HTTP_USER_AGENT' => 'Capybara' })
end
```

See the section on adding and configuring drivers.

### <a name="selenium"></a>Selenium

Capybara supports [Selenium 3.5+
(Webdriver)](https://www.seleniumhq.org/projects/webdriver/).
In order to use Selenium, you'll need to install the `selenium-webdriver` gem,
and add it to your Gemfile if you're using bundler.

Capybara pre-registers a number of named drivers that use Selenium - they are:

  * :selenium                 => Selenium driving Firefox
  * :selenium_headless        => Selenium driving Firefox in a headless configuration
  * :selenium_chrome          => Selenium driving Chrome
  * :selenium_chrome_headless => Selenium driving Chrome in a headless configuration

These should work (with relevant software installation) in a local desktop configuration but you may
need to customize them if using in a CI environment where additional options may need to be passed
to the browsers.  See the section on adding and configuring drivers.


**Note**: drivers which run the server in a different thread may not share the
same transaction as your tests, causing data not to be shared between your test
and test server, see [Transactions and database setup](#transactions-and-database-setup) below.

### <a name="apparition"></a>Apparition

The [apparition driver](https://github.com/twalpole/apparition) is a new driver that allows you to run tests using Chrome in a headless
or headed configuration. It attempts to provide backwards compatibility with the [Poltergeist driver API](https://github.com/teampoltergeist/poltergeist)
and [capybara-webkit API](https://github.com/thoughtbot/capybara-webkit) while allowing for the use of modern JS/CSS. It
uses CDP to communicate with Chrome, thereby obviating the need for chromedriver. This driver is being developed by the
current developer of Capybara and will attempt to keep up to date with new Capybara releases. It will probably be moved into the
teamcapybara repo once it reaches v1.0.

## <a name="the-dsl"></a>The DSL

*A complete reference is available at
[rubydoc.info](http://rubydoc.info/github/teamcapybara/capybara/master)*.

**Note: By default Capybara will only locate visible elements. This is because
 a real user would not be able to interact with non-visible elements.**

**Note**: All searches in Capybara are *case sensitive*. This is because
Capybara heavily uses XPath, which doesn't support case insensitivity.

### <a name="navigating"></a>Navigating

You can use the
<tt>[visit](http://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Session#visit-instance_method)</tt>
method to navigate to other pages:

```ruby
visit('/projects')
visit(post_comments_path(post))
```

The visit method only takes a single parameter, the request method is **always**
GET.

You can get the [current path](http://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Session#current_path-instance_method)
of the browsing session, and test it using the [`have_current_path`](http://www.rubydoc.info/github/teamcapybara/capybara/master/Capybara/RSpecMatchers#have_current_path-instance_method) matcher:

```ruby
expect(page).to have_current_path(post_comments_path(post))
```

**Note**: You can also assert the current path by testing the value of
`current_path` directly. However, using the `have_current_path` matcher is
safer since it uses Capybara's [waiting behaviour](#asynchronous-javascript-ajax-and-friends)
to ensure that preceding actions (such as a `click_link`) have completed.

### <a name="clicking-links-and-buttons"></a>Clicking links and buttons

*Full reference: [Capybara::Node::Actions](http://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Node/Actions)*

You can interact with the webapp by following links and buttons. Capybara
automatically follows any redirects, and submits forms associated with buttons.

```ruby
click_link('id-of-link')
click_link('Link Text')
click_button('Save')
click_on('Link Text') # clicks on either links or buttons
click_on('Button Value')
```

### <a name="interacting-with-forms"></a>Interacting with forms

*Full reference: [Capybara::Node::Actions](http://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Node/Actions)*

There are a number of tools for interacting with form elements:

```ruby
fill_in('First Name', with: 'John')
fill_in('Password', with: 'Seekrit')
fill_in('Description', with: 'Really Long Text...')
choose('A Radio Button')
check('A Checkbox')
uncheck('A Checkbox')
attach_file('Image', '/path/to/image.jpg')
select('Option', from: 'Select Box')
```

### <a name="querying"></a>Querying

*Full reference: [Capybara::Node::Matchers](http://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Node/Matchers)*

Capybara has a rich set of options for querying the page for the existence of
certain elements, and working with and manipulating those elements.

```ruby
page.has_selector?('table tr')
page.has_selector?(:xpath, './/table/tr')

page.has_xpath?('.//table/tr')
page.has_css?('table tr.foo')
page.has_content?('foo')
```

**Note:** The negative forms like `has_no_selector?` are different from `not
has_selector?`. Read the section on asynchronous JavaScript for an explanation.

You can use these with RSpec's magic matchers:

```ruby
expect(page).to have_selector('table tr')
expect(page).to have_selector(:xpath, './/table/tr')

expect(page).to have_xpath('.//table/tr')
expect(page).to have_css('table tr.foo')
expect(page).to have_content('foo')
```

### <a name="finding"></a>Finding

_Full reference: [Capybara::Node::Finders](http://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Node/Finders)_

You can also find specific elements, in order to manipulate them:

```ruby
find_field('First Name').value
find_field(id: 'my_field').value
find_link('Hello', :visible => :all).visible?
find_link(class: ['some_class', 'some_other_class'], :visible => :all).visible?

find_button('Send').click
find_button(value: '1234').click

find(:xpath, ".//table/tr").click
find("#overlay").find("h1").click
all('a').each { |a| a[:href] }
```

If you need to find elements by additional attributes/properties you can also pass a filter block, which will be checked inside the normal waiting behavior.
If you find yourself needing to use this a lot you may be better off adding a [custom selector](http://www.rubydoc.info/github/teamcapybara/capybara/Capybara#add_selector-class_method) or [adding a filter to an existing selector](http://www.rubydoc.info/github/teamcapybara/capybara/Capybara#modify_selector-class_method).

```ruby
find_field('First Name'){ |el| el['data-xyz'] == '123' }
find("#img_loading"){ |img| img['complete'] == true }
```

**Note**: `find` will wait for an element to appear on the page, as explained in the
Ajax section. If the element does not appear it will raise an error.

These elements all have all the Capybara DSL methods available, so you can restrict them
to specific parts of the page:

```ruby
find('#navigation').click_link('Home')
expect(find('#navigation')).to have_button('Sign out')
```

### <a name="scoping"></a>Scoping

Capybara makes it possible to restrict certain actions, such as interacting with
forms or clicking links and buttons, to within a specific area of the page. For
this purpose you can use the generic
<tt>[within](http://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Session#within-instance_method)</tt>
method. Optionally you can specify which kind of selector to use.

```ruby
within("li#employee") do
  fill_in 'Name', with: 'Jimmy'
end

within(:xpath, ".//li[@id='employee']") do
  fill_in 'Name', with: 'Jimmy'
end
```

There are special methods for restricting the scope to a specific fieldset,
identified by either an id or the text of the fieldset's legend tag, and to a
specific table, identified by either id or text of the table's caption tag.

```ruby
within_fieldset('Employee') do
  fill_in 'Name', with: 'Jimmy'
end

within_table('Employee') do
  fill_in 'Name', with: 'Jimmy'
end
```

### <a name="working-with-windows"></a>Working with windows

Capybara provides some methods to ease finding and switching windows:

```ruby
facebook_window = window_opened_by do
  click_button 'Like'
end
within_window facebook_window do
  find('#login_email').set('a@example.com')
  find('#login_password').set('qwerty')
  click_button 'Submit'
end
```

### <a name="scripting"></a>Scripting

In drivers which support it, you can easily execute JavaScript:

```ruby
page.execute_script("$('body').empty()")
```

For simple expressions, you can return the result of the script.

```ruby
result = page.evaluate_script('4 + 4');
```

For more complicated scripts you'll need to write them as one expression.

```ruby
result = page.evaluate_script(<<~JS, 3, element)
  (function(n, el){
    var val = parseInt(el.value, 10);
    return n+val;
  })(arguments[0], arguments[1])
JS
```

### <a name="modals"></a>Modals

In drivers which support it, you can accept, dismiss and respond to alerts, confirms and prompts.

You can accept or dismiss alert messages by wrapping the code that produces an alert in a block:

```ruby
accept_alert do
  click_link('Show Alert')
end
```

You can accept or dismiss a confirmation by wrapping it in a block, as well:

```ruby
dismiss_confirm do
  click_link('Show Confirm')
end
```

You can accept or dismiss prompts as well, and also provide text to fill in for the response:

```ruby
accept_prompt(with: 'Linus Torvalds') do
  click_link('Show Prompt About Linux')
end
```

All modal methods return the message that was presented. So, you can access the prompt message
by assigning the return to a variable:

```ruby
message = accept_prompt(with: 'Linus Torvalds') do
  click_link('Show Prompt About Linux')
end
expect(message).to eq('Who is the chief architect of Linux?')
```

### <a name="debugging"></a>Debugging

It can be useful to take a snapshot of the page as it currently is and take a
look at it:

```ruby
save_and_open_page
```

You can also retrieve the current state of the DOM as a string using
<tt>[page.html](http://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Session#html-instance_method)</tt>.

```ruby
print page.html
```

This is mostly useful for debugging. You should avoid testing against the
contents of `page.html` and use the more expressive finder methods instead.

Finally, in drivers that support it, you can save a screenshot:

```ruby
page.save_screenshot('screenshot.png')
```

Or have it save and automatically open:

```ruby
save_and_open_screenshot
```

Screenshots are saved to `Capybara.save_path`, relative to the app directory.
If you have required `capybara/rails`, `Capybara.save_path` will default to
`tmp/capybara`.

## <a name="matching"></a>Matching

It is possible to customize how Capybara finds elements. At your disposal
are two options, `Capybara.exact` and `Capybara.match`.

### <a name="exactness"></a>Exactness

`Capybara.exact` and the `exact` option work together with the `is` expression
inside the XPath gem. When `exact` is true, all `is` expressions match exactly,
when it is false, they allow substring matches. Many of the selectors built into
Capybara use the `is` expression. This way you can specify whether you want to
allow substring matches or not. `Capybara.exact` is false by default.

For example:

```ruby
click_link("Password") # also matches "Password confirmation"
Capybara.exact = true
click_link("Password") # does not match "Password confirmation"
click_link("Password", exact: false) # can be overridden
```

### <a name="strategy"></a>Strategy

Using `Capybara.match` and the equivalent `match` option, you can control how
Capybara behaves when multiple elements all match a query. There are currently
four different strategies built into Capybara:

1. **first:** Just picks the first element that matches.
2. **one:** Raises an error if more than one element matches.
3. **smart:** If `exact` is `true`, raises an error if more than one element
   matches, just like `one`. If `exact` is `false`, it will first try to find
   an exact match. An error is raised if more than one element is found. If no
   element is found, a new search is performed which allows partial matches. If
   that search returns multiple matches, an error is raised.
4. **prefer_exact:** If multiple matches are found, some of which are exact,
   and some of which are not, then the first exactly matching element is
   returned.

The default for `Capybara.match` is `:smart`. To emulate the behaviour in
Capybara 2.0.x, set `Capybara.match` to `:one`. To emulate the behaviour in
Capybara 1.x, set `Capybara.match` to `:prefer_exact`.

## <a name="transactions-and-database-setup"></a>Transactions and database setup

**Note:**  Rails 5.1+ "safely" shares the database connection between the app and test threads.  Therefore,
if using Rails 5.1+ you SHOULD be able to ignore this section.

Some Capybara drivers need to run against an actual HTTP server. Capybara takes
care of this and starts one for you in the same process as your test, but on
another thread. Selenium is one of those drivers, whereas RackTest is not.

If you are using a SQL database, it is common to run every test in a
transaction, which is rolled back at the end of the test, rspec-rails does this
by default out of the box for example. Since transactions are usually not
shared across threads, this will cause data you have put into the database in
your test code to be invisible to Capybara.

Cucumber handles this by using truncation instead of transactions, i.e. they
empty out the entire database after each test. You can get the same behaviour
by using a gem such as [database_cleaner](https://github.com/DatabaseCleaner/database_cleaner).

## <a name="asynchronous-javascript-ajax-and-friends"></a>Asynchronous JavaScript (Ajax and friends)

When working with asynchronous JavaScript, you might come across situations
where you are attempting to interact with an element which is not yet present
on the page. Capybara automatically deals with this by waiting for elements
to appear on the page.

When issuing instructions to the DSL such as:

```ruby
click_link('foo')
click_link('bar')
expect(page).to have_content('baz')
```

If clicking on the *foo* link triggers an asynchronous process, such as
an Ajax request, which, when complete will add the *bar* link to the page,
clicking on the *bar* link would be expected to fail, since that link doesn't
exist yet. However Capybara is smart enough to retry finding the link for a
brief period of time before giving up and throwing an error. The same is true of
the next line, which looks for the content *baz* on the page; it will retry
looking for that content for a brief time. You can adjust how long this period
is (the default is 2 seconds):

```ruby
Capybara.default_max_wait_time = 5
```

Be aware that because of this behaviour, the following two statements are **not**
equivalent, and you should **always** use the latter!

```ruby
!page.has_xpath?('a')
page.has_no_xpath?('a')
```

The former would immediately fail because the content has not yet been removed.
Only the latter would wait for the asynchronous process to remove the content
from the page.

Capybara's RSpec matchers, however, are smart enough to handle either form.
The two following statements are functionally equivalent:

```ruby
expect(page).not_to have_xpath('a')
expect(page).to have_no_xpath('a')
```

Capybara's waiting behaviour is quite advanced, and can deal with situations
such as the following line of code:

```ruby
expect(find('#sidebar').find('h1')).to have_content('Something')
```

Even if JavaScript causes `#sidebar` to disappear off the page, Capybara
will automatically reload it and any elements it contains. So if an AJAX
request causes the contents of `#sidebar` to change, which would update
the text of the `h1` to "Something", and this happened, this test would
pass. If you do not want this behaviour, you can set
`Capybara.automatic_reload` to `false`.

## <a name="using-the-dsl-elsewhere"></a>Using the DSL elsewhere

You can mix the DSL into any context by including <tt>Capybara::DSL</tt>:


```ruby
require 'capybara/dsl'

Capybara.default_driver = :webkit

module MyModule
  include Capybara::DSL

  def login!
    within(:xpath, ".//form[@id='session']") do
      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password'
    end
    click_button 'Sign in'
  end
end
```

This enables its use in unsupported testing frameworks, and for general-purpose scripting.

## <a name="calling-remote-servers"></a>Calling remote servers

Normally Capybara expects to be testing an in-process Rack application, but you
can also use it to talk to a web server running anywhere on the internet, by
setting app_host:

```ruby
Capybara.current_driver = :selenium
Capybara.app_host = 'http://www.google.com'
...
visit('/')
```

**Note**: the default driver (`:rack_test`) does not support running
against a remote server. With drivers that support it, you can also visit any
URL directly:

```ruby
visit('http://www.google.com')
```

By default Capybara will try to boot a rack application automatically. You
might want to switch off Capybara's rack server if you are running against a
remote application:

```ruby
Capybara.run_server = false
```

## <a name="using-sessions"></a>Using sessions

Capybara manages named sessions (:default if not specified) allowing multiple sessions using the same driver and test app instance to be interacted with.
A new session will be created using the current driver if a session with the given name using the current driver and test app instance is not found.

### Named sessions
To perform operations in a different session and then revert to the previous session

```ruby
Capybara.using_session("Bob's session") do
   #do something in Bob's browser session
end
 #reverts to previous session
```

To permanently switch the current session to a different session

```ruby
Capybara.session_name = "some other session"
```

### <a name="using-sessions-manually"></a>Using sessions manually

For ultimate control, you can instantiate and use a
[Session](http://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Session)
manually.

```ruby
require 'capybara'

session = Capybara::Session.new(:webkit, my_rack_app)
session.within("form#session") do
  session.fill_in 'Email', with: 'user@example.com'
  session.fill_in 'Password', with: 'password'
end
session.click_button 'Sign in'
```

## <a name="xpath-css-and-selectors"></a>XPath, CSS and selectors

Capybara does not try to guess what kind of selector you are going to give it,
and will always use CSS by default.  If you want to use XPath, you'll need to
do:

```ruby
within(:xpath, './/ul/li') { ... }
find(:xpath, './/ul/li').text
find(:xpath, './/li[contains(.//a[@href = "#"]/text(), "foo")]').value
```

Alternatively you can set the default selector to XPath:

```ruby
Capybara.default_selector = :xpath
find('.//ul/li').text
```

Capybara provides a number of other built-in selector types. The full list, along
with applicable filters, can be seen at [built-in selectors](https://www.rubydoc.info/github/teamcapybara/capybara/Capybara/Selector)

Capybara also allows you to add custom selectors, which can be very useful if you
find yourself using the same kinds of selectors very often. The examples below are very
simple, and there are many available features not demonstrated. For more in-depth examples
please see Capybaras built-in selector definitions.

```ruby
Capybara.add_selector(:my_attribute) do
  xpath { |id| XPath.descendant[XPath.attr(:my_attribute) == id.to_s] }
end

Capybara.add_selector(:row) do
  xpath { |num| ".//tbody/tr[#{num}]" }
end

Capybara.add_selector(:flash_type) do
  css { |type| "#flash.#{type}" }
end
```

The block given to xpath must always return an XPath expression as a String, or
an XPath expression generated through the XPath gem. You can now use these
selectors like this:

```ruby
find(:my_attribute, 'post_123') # find element with matching attribute
find(:row, 3) # find 3rd row in table body
find(:flash_type, :notice) # find element with id of 'flash' and class of 'notice'
```

## <a name="beware-the-xpath--trap"></a>Beware the XPath // trap

In XPath the expression // means something very specific, and it might not be what
you think. Contrary to common belief, // means "anywhere in the document" not "anywhere
in the current context". As an example:

```ruby
page.find(:xpath, '//body').all(:xpath, '//script')
```

You might expect this to find all script tags in the body, but actually, it finds all
script tags in the entire document, not only those in the body! What you're looking
for is the .// expression which means "any descendant of the current node":

```ruby
page.find(:xpath, '//body').all(:xpath, './/script')
```
The same thing goes for within:

```ruby
within(:xpath, '//body') do
  page.find(:xpath, './/script')
  within(:xpath, './/table/tbody') do
  ...
  end
end
```

## <a name="configuring-and-adding-drivers"></a>Configuring and adding drivers

Capybara makes it convenient to switch between different drivers. It also exposes
an API to tweak those drivers with whatever settings you want, or to add your own
drivers. This is how to override the selenium driver configuration to use chrome:

```ruby
Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end
```

However, it's also possible to give this configuration a different name.

```ruby
# Note: Capybara registers this by default
Capybara.register_driver :selenium_chrome do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end
```

Then tests can switch between using different browsers effortlessly:
```ruby
Capybara.current_driver = :selenium_chrome
```

Whatever is returned from the block should conform to the API described by
Capybara::Driver::Base, it does not however have to inherit from this class.
Gems can use this API to add their own drivers to Capybara.

The [Selenium wiki](https://github.com/SeleniumHQ/selenium/wiki/Ruby-Bindings) has
additional info about how the underlying driver can be configured.

## <a name="gotchas"></a>Gotchas:

* Access to session and request is not possible from the test, Access to
  response is limited. Some drivers allow access to response headers and HTTP
  status code, but this kind of functionality is not provided by some drivers,
  such as Selenium.

* Access to Rails specific stuff (such as `controller`) is unavailable,
  since we're not using Rails' integration testing.

* Freezing time: It's common practice to mock out the Time so that features
  that depend on the current Date work as expected. This can be problematic on
  ruby/platform combinations that don't support access to a monotonic process clock,
  since Capybara's Ajax timing uses the system time, resulting in Capybara
  never timing out and just hanging when a failure occurs. It's still possible to
  use gems which allow you to travel in time, rather than freeze time.
  One such gem is [Timecop](https://github.com/travisjeffery/timecop).

* When using Rack::Test, beware if attempting to visit absolute URLs. For
  example, a session might not be shared between visits to `posts_path`
  and `posts_url`. If testing an absolute URL in an Action Mailer email,
  set `default_url_options` to match the Rails default of
  `www.example.com`.

* Server errors will only be raised in the session that initiates the server thread. If you
  are testing for specific server errors and using multiple sessions make sure to test for the
  errors using the initial session (usually :default)

* If WebMock is enabled, you may encounter a "Too many open files"
  error. A simple `page.find` call may cause thousands of HTTP requests
  until the timeout occurs. By default, WebMock will cause each of these
  requests to spawn a new connection. To work around this problem, you
  may need to [enable WebMock's `net_http_connect_on_start: true`
  parameter](https://github.com/bblimke/webmock/blob/master/README.md#connecting-on-nethttpstart).

## <a name="threadsafe"></a>"Threadsafe" mode

In normal mode most of Capybara's configuration options are global settings which can cause issues
if using multiple sessions and wanting to change a setting for only one of the sessions.  To provide
support for this type of usage Capybara now provides a "threadsafe" mode which can be enabled by setting

```ruby
Capybara.threadsafe = true
```

This setting can only be changed before any sessions have been created.  In "threadsafe" mode the following
behaviors of Capybara change

* Most options can now be set on a session.  These can either be set at session creation time or after, and
  default to the global options at the time of session creation.  Options which are NOT session specific are
  `app`, `reuse_server`, `default_driver`, `javascript_driver`, and (obviously) `threadsafe`.  Any drivers and servers
  registered through `register_driver` and `register_server` are also global.

  ```ruby
  my_session = Capybara::Session.new(:driver, some_app) do |config|
    config.automatic_label_click = true # only set for my_session
  end
  my_session.config.default_max_wait_time = 10 # only set for my_session
  Capybara.default_max_wait_time = 2 # will not change the default_max_wait in my_session
  ```

* `current_driver` and `session_name` are thread specific.  This means that `using_session` and
  `using_driver` also only affect the current thread.

## <a name="development"></a>Development

To set up a development environment, simply do:

```bash
bundle install
bundle exec rake  # run the test suite with Firefox - requires `geckodriver` to be installed
bundle exec rake spec_chrome # run the test suite with Chrome - require `chromedriver` to be installed
```

See
[CONTRIBUTING.md](https://github.com/teamcapybara/capybara/blob/master/CONTRIBUTING.md)
for how to send issues and pull requests.
