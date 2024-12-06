# Version 3.37.1
Relesae date: 2022-05-09

### Fixed

* Regression in rack-test visit - Issue #2548

# Version 3.37.0
Release date: 2022-05-07

### Changed

* Ruby 2.7.0+ is now required

### Added

* [Beta] CSP nonces inserted into animation disabler additions - Issue #2542
* Support `<base>` element in rack-test driver - ISsue #2544
* [Beta] `Element#shadow_root` support. Requires selenium-webdriver 4.1+. Only currently supported with Chrome when using the selenium driver. Note: only CSS can be used to find elements from the shadow root. Therefore you won't be able to use most Capybara helper methods (`fill_in`, `click_link`, `find_field`, etc) directly from the shadow root since those locators are built using XPath. If you first locate a descendant from the shadow root using CSS then you should be able to use all the Capybara methods from there.
* Regexp now supported for `exact_text` finder option

### Fixed

* Fragments in referer headers in rack-test driver - Issue #2525
* Selenium v4.1 deprecation notice

# Version 3.36.0
Release date: 2021-10-24

### Changed

* Ruby 2.6.0+ is now required
* Minimum selenium-webdriver supported is now 3.142.7

### Added

* Support for selenium-webdriver 4.x
* `allow_label_click` accepts click options to be used when clicking an associated label
* Deprecated `allow_gumbo=` in favor of `use_html5_parsing=` to enable use of Nokogiri::HTML5 when available
* `Session#active_element` returns the element with focus - Not supported by the `RackTest` driver [Sean Doyle]
* Support `focused:` filter for finding interactive elements - Not supported by the `RackTest` driver [Sean Doyle]

### Fixed

* Sibling and ancestor queries now work with Simple::Node - Issue #2452
* rack_test correctly ignores readonly attribute on specific input element types
* `Node#all_text` always returns a string - Issue #2477
* `have_any_of_selectors` negated match - Issue #2473
* `Document#scroll_to` fixed for standards behavior - pass quirks: true if you need the older behavior [Eric Anderson]
* Use capture on attach file event listener for better React compatibility [Jeff Way]
* Animation disabler produces valid HTML [Javi Martin]

### Removed

* References to non-w3c mode in drivers/tests. Non-w3c mode is obsolete and no one should be using it anymore. Capybara hasn't been testing/supporting it in a while

# Version 3.35.3
Release date: 2021-01-29

### Fixed

* Just a release to have the correct dates in the History.md in released gem

# Version 3.35.2
Release date: 2021-01-29

### Fixed

* Selenium deprecation suppressor with Selenium 3.x

# Version 3.35.1
Release date: 2021-01-26

### Fixed

* Default chrome driver registrations use chrome - Issue #2442 [Yuriy Alekseyev]
* 'Capybara.test_id' usage with the :button selector - Issue #2443

# Version 3.35.0
Release date: 2021-01-25

### Added

* Support Regexp matching for individual class names in :class filter passed an Array
* Animation disabler now supports JQuery animation disabling when JQuery loaded from body [Chien-Wei Huang]

### Fixed

* :button selector type use with `enable_aria_role` [Sean Doyle]
* <label> elements don't associate with aria-role buttons
* Ignore Selenium::WebDriver::Error::InvalidSessionIdError when quitting driver [Robin Daugherty]
* Firefox: Don't click input when sending keys if already focused
* Miscellaneous issues with selenium-webdriver 4.0.0.alphas
* Nil return error in node details optimizations
* Animation disabler now inserts XHTML compliant content [Dale Morgan]

# Version 3.34.0
Release date: 2020-11-26

### Added

* Ability to fill in with emoji when using Chrome with selenium driver (Firefox already worked)
* Current path assertions/expectations accept optional filter block
* Animation disabler now specifies `scroll-behavior: auto;` [Nathan Broadbent]
* :button selector can now find elements by label text [Sean Doyle]
* `Session#send_keys` to send keys to the current element with focus in drivers that support the
  concept of a current element [Sean Doyle]

### Changed

* Text query validates the type parameter to prevent undefined behavior

### Fixed

* racktest driver better handles fragments and redirection to urls that include fragments
* Don't error when attempting to get XPath location of a shadow element
* Missing `readonly?` added to Node::Simple
* Selenium version detection when loaded via alternate method [Joel Hawksley]
* Connection count issue if REQUEST_URI value changed by app [Blake Williams]
* Maintain URI fragment when redirecting in rack-test driver
* Text query error message [Wojciech Wnętrzak]
* Checking a checkbox/radio button with `allow_label_click` now works if there are multiple labels (Issue #2421)
* `drop` with `Pathname` (Issue #2424)[Máximo Mussini]

# Version 3.33.0
Release date: 2020-06-21

### Added

* Block passed to `within_session` now receives the new and old session
* Support for aria-role button when enabled [Seiei Miyagi]
* Support for aria-role link when enabled
* Support for `validation_message` filter with :field and :fillable_field selectors
* Deprecation warnings show source location [Koichi ITO]

### Changed

* Ruby 2.5.0+ is now required
* Deprecated direct manipulation of the driver and server registries

### Fixed

* Ruby 2.7 warning in minitest `assert_text` [Eileen M. Uchitelle]


# Version 3.32.2
Release date: 2020-05-16

### Fixed

* Don't use lazy enumerator with JRuby due to leaking threads
* Ruby 2.7 deprecation warning when registering Webrick [Jon Zeppieri]
* `have_text` description [Juan Pablo Rinaldi]

# Version 3.32.1
Release date: 2020-04-05

### Fixed

* Rapid set now respects field maxlength (Issue #2332)
* Only patch pause into legacy actions in Selenium < 4 (Issue #2334)

# Version 3.32.0
Release date: 2020-03-29

### Added

* Support `delay` setting on click with Selenium
* Implement rapid set for values longer than 30 characters in text fields with Selenium

### Fixed

* Result#[] and negative max on ranges (Issue #2302/2303) [Jeremy Evans]
* RackTest form submission rewrites query string when using GET method
* Ruby 2.7 deprecation warnings in RSpec matcher proxies

# Version 3.31.0
Release date: 2020-01-26

### Added

* Support setting range inputs with the selenium driver [Andrew White]
* Support setting range inputs with the rack driver
* Support drop modifier keys in drag & drop [Elliot Crosby-McCullough]
* `enabled_options` and `disabled options` filters for select selector
* Support beginless ranges
* Optionally allow `all` results to be reloaded when stable - Beta feature - may be removed in
  future version if problems occur

### Fixed

* Fix Ruby 2.7 deprecation notices around keyword arguments. I have tried to do this without
  any breaking changes, but due to the nature of the 2.7 changes and some selector types accepting
  Hashes as locators there are a lot of edge cases. If you find any broken cases please report
  them and I'll see if they're fixable.
* Clicking on details/summary element behavior in rack_test driver_

# Version 3.30.0
Release date: 2019-12-24

### Added

* Display pending requests when they don't complete in time [Juan Carlos Medina]
* :order option in selector queries - set to :reverse to for reverse document order results
* Support regexp for :name and :placeholder options in selectors that import filters from
  _field filter set

### Fixed

* Issue around automatic port assignment - Issue #2245
* Label selector when label has no id - Issue #2260
* Preserve clientX/clientY in Selenium HTML5 drag emulation [Nicolò G.]
* table selector using :with_cols option if last specified column matched but others didn't - Issue #2287
* Some tests updated for Ruby 2.7 behavior change around keyword args

# Version 3.29.0
Release date: 2019-09-02

### Added

* Allow clicking on file input when using the block version of `attach_file` with Chrome and Firefox
* Spatial filters (`left_of`, `right_of`, `above`, `below`, `near`)
* rack_test driver now supports clicking on details elements to open/close them

### Fixed

* rack_test driver correctly determines visibility for open details elements descendants

### Changed

* Results will now be lazily evaluated when using JRuby >= 9.2.8.0


# Version 3.28.0
Release date: 2019-08-03

### Added

* Allow forcing HTML5 or legacy dragging via the `:html5` option to `drag_to` when using Selenium with Chrome or Firefox
* Autodetection of drag type interprets not seeing the mousedown event as legacy.
* HTML5 form validation `:valid` node filter added to `:field` and `:fillable_field` selectors
* When using Capybara registered :puma server - patches Puma 4.0.x to fix SSL connection behavior. Removes
  default `queue_requests` setting - Issue #2227

# Version 3.27.0
Release date: 2019-07-28

### Added

* Allow to use chromedriver/geckodriver native `is_element_displayed` endpoint via Selenium
  driver `native_displayed` option for performance reasons. Disabled by default due to endpoints
  currently not handling &lt;details> element descendants visibility correctly.

### Fixed

* Ignore negative lookahead/lookbehind regex when performing initial XPath text matching
* Reloading of elements found via `ancestor` and `sibling`
* Only default puma settings to `queue_requests: false` when using SSL
* Visibility of descendants of &lt;details> elements is correctly determined when using rack_test
  and the selenium driver with Capybara optimized atoms
* local/session storage clearance in Chrome when clearing only one of them - Issue #2233

# Version 3.26.0
Release date: 2019-07-15

### Added

* `w3c_click_offset` configuration option applies to `right_click` and `double_click` as well as `click`
* Warning when passing `nil` to the text/content assertions/expectations
* `Session#server_url` returns the base url the AUT is being run at (when controlled by Capybara)
* `option` selector type accepts an integer as locator

### Fixed

* Default puma server registration now specifies `queue_requests: false` - Issue #2227
* Workaround issue with FF 68 and hanging during reset if a system modal is visible
* Don't expand file path if it's already absolute - Issue #2228

# Version 3.25.0
Release date: 2019-06-27

### Added

* Animation disabler also disables before and after pseudoelements - Issue #2221 [Daniel Heath]
* `w3c_click_offset` configuration option to determine whether click offsets are calculated from element
  center or top left corner

### Fixed

* Work around issue with chromedriver 76/77 in W3C mode losing mouse state during legacy drag. Only fixed if
  both source and target are simultaneously inside the viewport - Issue #2223
* Negative ancestor expectations/predicates were incorrectly checking siblings rather than ancestors

# Version 3.24.0
Release date: 2019-06-13

### Added

* Log access when using the Selenium driver with Chrome 75 in W3C mode has been reenabled.

### Changed

* Selenium driver now selects all current content and then sends keys rather than clearing field by JS
  and then sending keys when setting values to text inputs in order to more closely simulate user behavior

### Fixed

* Relative paths passed to `attach_file` will be assumed to be relative to the current working directory when using the
  Selenium driver

# Version 3.23.0
Release date: 2019-06-10

### Added

* Improved error message when using Chrome in W3C mode and attempting to access logs
* Support driver specific options for Element#drag_to
* Support setting `<input type="color">` elements with the selenium driver

### Fixed

* Tightened conditions when in expression text option matching will be used
* Improved Selenium drivers HTML5 drag and drop emulation compatibility with SortableJS library (and others)

# Version 3.22.0
Release date: 2019-05-29

### Added

* `ancestor`/`sibling` assertions and matchers added
* Documentation Updates and Fixes - Many thanks again to Masafumi Koba! [Masafumi Koba]
* Added `:with` alias for `:option` filter on `:checkbox` and `:radio_button` selectors

### Changed

* Selenium driver with Chrome >= 73 now resets cookies and local/session storage after navigating
  to 'about:blank' when possible to minimize potential race condition

# Version 3.21.0
Release date: 2019-05-24

### Added

* Element#drop - Chrome and Firefox, via the selenium driver, support dropping files/data on elements
* Default CSS used for `attach_file` `make_visible: true` now includes auto for
  height and width to handle more ways of hiding the file input element
* Documentation Updates and Fixes - Many thanks to Masafumi Koba! [Masafumi Koba]

### Changed

* Deprecate support for CSS locator being a Symbol

# Version 3.20.2
Release date: 2019-05-19

### Fixed

* Move `uglifier` from runtime to development dependency [miyucy]

# Version 3.20.1
Release date: 2019-05-17

### Fixed

* RackTest driver considers &lt;template> elements to be non-visible and ignores the contents

# Version 3.20.0
Release date: 2019-05-14

### Added

* `Node#obscured?` to check viewport presence and element overlap
* `:obscured` system filter to check whether elements are obscured in finders, assertions, and expectations
* :label selector :for option can be a regexp
* Significantly smaller `isDisplayed`/`getAttribute` atoms for selenium driver. If these produce issues you can disable their use
  by setting an environment variable named 'DISABLE_CAPYBARA_SELENIUM_OPTIMIZATIONS' (Please also report any issues).
* `href: false` option with `find_link`/`click_link`/:link selector ignores `href` presence/absence

### Fixed

* Workaround Safari issue with send_keys not correctly using top level modifiers
* Workaround Safari not retrying click due to incorrect error type
* Fix Safari attach_file block mode when clicking elements associated to the file input
* Workaround Safari issue with repeated hover

# Version 3.19.1
Release date: 2019-05-11

### Fixed

* Fix access to specializations when Selenium::Driver is subclassed [James Mead]

# Version 3.19.0
Release date: 2019-05-09

### Added


* Syntactic sugar `#once`, `#twice`, `#thrice`, `#exactly`, `#at_least`, `#at_most`, and `#times`
  added to `have_selector`, `have_css`, `have_xpath`, and `have_text` RSpec matchers
* Support for multiple expression types in Selector definitions
* Reduced wirecalls for common actions in Selenium driver

### Fixed

* Workaround Chrome 75 appending files to multiple file inputs
* Suppressed retry when detecting http vs https server connection

# Version 3.18.0
Release date: 2019-04-22

### Added

* XPath Selector query optimized to make use of Regexp :text option in initial element find

### Fixed

* Workaround issue where Chrome/chromedriver 74 can return the wrong error type when a click is intercepted

# Version 3.17.0
Release date: 2019-04-18

### Added

* Initial support for selenium-webdriver 4.0.0.alpha1
* :button selector will now also match on `name` attribute

### Fixed

* Suppress warnings generated by using selenium-webdriver 3.141.5926
* Mask Appium issue with finder visibility optimizations (non-optimal)

# Version 3.16.2
Release date: 2019-04-10

### Fixed

* Fix Session#quit resetting of memoized document

# Version 3.16.1
Release date: 2019-03-30

### Fixed

* Fix potential 'uninitialized constant' error when using the :selenium_chrome driver [jeffclemens-ab]

# Version 3.16
Release date: 2019-03-28

### Changed

* Ruby 2.4.0+ is now required
* Selenium driver now defaults to using a persistent http client connection

### Added

* :wait option in predicates now accepts `true` to selectively override when `Capybara.predicates_wait == false`

# Version 3.15
Release date: 2019-03-19

### Added

* `attach_file` now supports a block mode on JS capable drivers to more accurately test user behavior when file inputs are hidden (beta)
* :table selector now supports `with_rows`, 'rows', `with_cols`, and 'cols' filters

### Fixed

* Fix link selector when `Capybara.test_id` is set - Issue #2166 [bingjyang]


# Version 3.14
Release date: 2019-02-25

### Added

* rack_test driver now supports reloading elements when the document changes - Issue #2157
* Selenium driver HTML5 drag-drop emulation now emits multiple move events so drag direction
  is determinable [Erkki Eilonen, Thomas Walpole]
* Capybara.server_errors now defaults to [Exception] - Issue #2160 [Edgars Beigarts]
### Fixed

* Workaround hover issue with FF 65 - Issue #2156
* Workaround chromedriver issue when setting blank strings to react controlled text fields
* Workaround chromedriver issue with popup windows not loading content - https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary

# Version 3.13.2
Release date: 2019-01-24

### Fixed

* Remove extraneous output

# Version 3.13.1
Release date: 2019-01-24

### Fixed

* Only use Selenium visibility optimization when JS atom is available - Issue #2151

# Version 3.13.0
Release date: 2019-01-23

### Added

* Session#quit added
* #scroll_to added to allow scrolling page/elements to specified locations
* Speed optimizations around multiple element location and path generation when using the Selenium driver
* Support for locator type checking in custom selectors
* Allow configuration of gumbo use - defaults to off
* `assert_style`/`has_style`/`have_style` deprecated in favor of `assert_matches_style`/`matches_styles?`/`match_style`
* :style filter added to selectors

# Version 3.12.0
Release date: 2018-11-28

### Added

* Support Ruby 2.6 endless range in Result#[] and query `:between` option
* Pre-registered headless firefox driver :selenium_headless [Andrew Havens]
* Selenium driver now defaults to clearing `sessionStorage` and `localStorage`. To disable pass `clear_local_storage: false` and/or `clear_session_storage: false` when creating Capybara::Selenium::Driver instance in your driver registration

### Fixed

* Raise error if only :x or :y are passed as an offset to click methods

### Removed

* Support for RSpec < 3.5

# Version 3.11.1
Release date: 2018-11-16

### Fixed

* Fixed :link_or_button XPath generation when it has had an expression filter added

# Version 3.11.0
Release date: 2018-11-14

### Added

* Ability for node filters to set detailed error messages
* `Capybara::HTML` Will use `nokogumbo` for HTML parsing if installed
* `Selector#locator_filter` added to allow for dynamic locator in selectors

### Fixed

* Node filters are evaluated in the context of the Selector they are used in to ensure the correct options are used

# Version 3.10.1
Release date: 2018-11-03

### Fixed

* Fix `aria-label` and `test_id` matching for `link_or_button` selector type - Issue #2125
* Fixed crash in element path creation for matcher failure messages - Issue #2120

# Version 3.10.0
Release date: 2018-10-23

### Added

* :class filter can now check for class names starting with !
* Selector `xpath`/`css` expression definitions will get filter names from block parameters if not explicitly provided
* `any_of_selectors` assertions and matchers to complement `all_of_selectors` and `none_of_selectors`

### Fixed

* Selector `css` expression definition declared filters now work again
* Cleaned up warnings [Yuji Yaginuma]
* Workaround installation of rspec matcher proxies under jruby by reverting to the old solution not using prepend, so jruby bugs are not hit - Issue #2115

# Version 3.9.0
Release date: 2018-10-03

### Added

* Selenium with Chrome removes all cookies at session reset instead of just cookies from current domain if possible
* Support for Regexp for system :id and :class filters where possible
* `using_session` now accepts a session object as well as the name of the session for users who  manually manage sessions
* The `:field` selector will now find `type = "hidden"` fields if the `type: "hidden"` filter option is provided

# Version 3.8.2
Release date: 2018-09-26

### Fixed

* Fixed negated class selector option - Issue #2103

# Version 3.8.1
Release date: 2018-09-22

### Fixed

* Filling in of date fields with a string when using selenium chrome regression [Micah Geisel]

# Version 3.8.0
Release date: 2018-09-20

### Added

* Workaround geckodriver 0.22 issue with undefined pause durations
* :element selector ignores XML namespaces

### Fixed

* Added Errno::ECONNRESET to the errors which will allows https server detection

# Version 3.7.2
Release date: 2018-09-12

### Fixed

* Fix MatchQuery based matchers when used on a root element found using any type of parent/ancestor query - Issue #2097

* Fix Chrome/FF HTML5 drag simulation for elements (a, img) which default to draggable - Issue #2098

# Version 3.7.1
Release date: 2018-09-05

### Fixed

* Restored ability to pass symbol as the CSS selector when calling `has_css?`/`have_css`/etc - Issue #2093

# Version 3.7.0
Release date: 2018-09-02

### Added

* `Capybara.disable_animation` can be set to a CSS selector to identify which elements will have animation disabled [Michael Glass]
* `Capybara.default_normalize_ws` option which sets whether or not text predicates and matchers (`has_text?`, `has_content?`, `assert_text`, etc) use `normalize_ws` option by default. Defaults to false. [Stegalin Ivan]
* Selector based predicates, matchers, and finders now support the `:normalize_ws` option for the `:text`/`:exact_text` filters. Defaults to the `Capybara.default_normalize_ws`setting above.
* Element `choose`/`check`/`uncheck`/`attach_file`/`fill_in` can now operate on the element they're called on or a descendant if no locator is passed.

### Fixed

* All CSS styles applied by the `Element#attach_file` `:make_visible` option will now have `!important` priority set to ensure they override any other specified style.
* Firefox file inputs are only manually cleared when necessary.

# Version 3.6.0
Release date: 2018-08-14

### Added

* Workaround geckodriver/firefox send_keys issues as much as possible using the Selenium actions API
* Workaround lack of HTML5 native drag and drop events when using Selenium driver with Chrome and FF >= 62
* `Capybara.predicates_wait` option which sets whether or not Capybaras matcher predicate methods (`has_css?`, `has_selector?`, `has_text?`, etc.) default to using waiting/retrying behavior (defaults to true)

# Version 3.5.1
Release date: 2018-08-03

### Fixed

* Fixed misspelled method name `refute_matches_elector` => `refute_matches_selector`

# Version 3.5.0
Release date: 2018-08-01

### Added

* text predicates and matchers (`has_text?`, `has_content?`, `assert_text`, etc) now support a `normalize_ws` option

### Fixed

* `attach_file` with Selenium and local Firefox 62+ now correctly generates only one change event when attaching multiple files

# Version 3.4.2
Release date: 2018-07-24

### Fixed

* `match_xxx` selectors and `matches_xxx?` predicates work correctly with elements found using a sibling selector - Issue #2073

# Version 3.4.1
Release date: 2018-07-20

### Fixed

* `Session#evaluate_script` now strips the script in `Session` rather than only in the Selenium driver

# Version 3.4.0
Release date: 2018-07-19

### Fixed

* Make selenium driver :backspace clear strategy work even if caret location is in middle of field content [Champier Cyril]
* Selenium issue with fieldset nested in disabled fieldset not being considered disabled
* `Session#evaluate_script` and `Element#evaluate_script` now strip leading/trailing whitespace from scripts [Ian Lesperance]

### Added

* Work around Selenium lack of support for `file_detector` with remote geckodriver
* `#within_frame` locator is optional when only one frame exists
* `Capybara.test_id` option that allows for matching the Capybara provided selector types on an arbitrary attribute
  (defaults to nil), set to your test id attribute ('data-test-id, etc) if using test id attributes in your project

# Version 3.3.1
Release date: 2018-06-27

### Fixed

* `selenium-webdriver` version check [ahorek]
* Selenium driver correctly responds to `disabled?` for fieldset elements - Issue #2059 [Thomas Walpole]

# Version 3.3.0
Release date: 2018-06-25

### Added

* RackTest driver now handles 307/308 redirects
* `execute_async_script` can now be called on elements to run the JS in the context of the element
* `:download` filter option on `:link' selector
* `Window#fullscreen`
* `Element#style` and associated matchers

### Changed

* Minimum "supported" `selenium-webdriver` is raised to 3.5.0 (but you really should be using newer than that)

### Fixes

* Selenium driver with Firefox workaround for clicking on table row - https://github.com/mozilla/geckodriver/issues/1228
* :class and :id filters applied to CSS based selectors now correctly handle the CSS comma
* Selenium driver handles namespaces when generating an elements `#path` - Issue #2048

# Version 3.2.1
Release date: 2018-06-04

### Fixes

* Only split CSS selectors when :class or :id options are given. Restores 3.1.1 functionality for now but the underlying issue
  will require a larger fix, hopefully coming soon. - Issue #2044 [Thomas Walpole]

# Version 3.2.0
Release date: 2018-06-01

### Changed

* Ruby 2.3.0+ is now required
* `ElementNotFound` errors raised in selector filters are interpreted as non-matches

### Added

* New global configuration `default_set_options` used in `Capybara::Node::Element#set` as default `options` hash [Champier Cyril]
* `execute_script` and `evaluate_script` can now be called on elements to run the JS in the context of the element [Thomas Walpole]
* Filters in custom selectors now support a `matcher` Regexp to handle multiple filter options [Thomas Walpole]
* `:element` selector type which will match on any attribute (other than the reserved names) passed as a filter option [Thomas Walpole]
* `:class` filter option now supports preceding class names with `!` to indicate not having that class [Thomas Walpole]
* `:class` and `:id` filter options now accept `XPath::Expression` objects to allow for more flexibility in matching [Thomas Walpole]
* `Capybara.disable_animation` setting which triggers loading of a middleware that attempts to disable animations in pages.
  This is very much a beta feature and may change/disappear in the future. [Thomas Walpole]

# Version 3.1.1
Release date: 2018-05-25

### Fixes

* Ensure keystrokes are sent when setting time/date fields to a string with the Selenium driver [Thomas Walpole]

# Version 3.1.0
Release date: 2018-05-10

### Added

* Support for using `select` with text inputs associated with a datalist element
* `type` filter on `:button` selector
* Support for server operating in https mode
* Selenium driver now uses JS to fill_in/set date and time fields when passed date or time objects [Aleksei Gusev, Thomas Walpole]

# Version 3.0.3
Release date: 2018-04-30

### Fixes

* Issue in `check` where the locator string could not be omitted
* Selenium browser type detection when using remote [Ian Ker-Seymer]
* Potential hang when waiting for requests to complete [Chris Zetter]

# Version 3.0.2
Release date: 2018-04-13

### Fixes

* Fix expression filter descriptions in some selector failure messages
* Fix compounding of negated matchers - Issue #2010

# Version 3.0.1
Release date: 2018-04-06

### Changed

* Restored ability for `Capybara.server=` to accept a proc which was accidentally removed in 3.0.0

# Version 3.0.0
Release date: 2018-04-05

### Changed

* Selenium driver only closes extra windows for browsers where that is known to work (Firefox, Chrome)
* "threadsafe" mode is no longer considered beta

### Fixes

* Multiple file attach_file with Firefox
* Use Puma::Server directly rather than Rack::Handler::Puma so signal handlers don't prevent test quitting

# Version 3.0.0.rc2
Release date: 2018-03-23

### Changed

* Visibile text whitespace is no longer fully normalized in favor of being more in line with the WebDriver spec for visible text
* Drivers are expected to close extra windows when resetting the session
* Selenium driver supports Date/Time when filling in date/time/datetime-local inputs
* `current_url` returns the url for the top level browsing context
* `title` returns the title for the top level browsing context

### Added

* `Driver#frame_url` returns the url for the current frame
* `Driver#frame_title` returns the title for the current frame

# Version 3.0.0.rc1
Release date: 2018-03-02

### Added
* Support for libraries wrapping Capybara elements and providing a `#to_capybara_node` method

### Changed

* `first` now raises ElementNotFound, by default, instead of returning nil when no matches are found  - Issue #1507
* 'all' now waits for at least one matching element by default.  Pass `wait: false` if you want the previous
  behavior where an empty result would be returned immediately if no matching elements exist yet.
* ArgumentError raised if extra parameters passed to selector queries

### Removed

* Ruby < 2.2.2 support
* `Capybara.exact_options` no longer exists. Just use `exact: true` on relevant actions/finders if necessary.
* All previously deprecated methods removed
* RSpec 2.x support
* selenium-webdriver 2.x support
* Nokogiri < 1.8 support
* `field_labeled` alias for `find_field`

# Version 2.18.0
Release date: 2018-02-12

### Fixed

* Firefox/geckodriver setting of contenteditable childs contents
* Ignore Selenium::WebDriver::Error::SessionNotCreatedError when quitting driver [Tim Connor]

### Removed

* Headless chrome modal JS injection that is no longer needed for Chrome 64+/chromedriver 2.35+


# Version 2.17.0
Release date: 2018-01-02

### Added

* `have_all_of_selectors`, `have_none_of_selectors` RSpec matchers for parity with minitest assertions [Thomas Walpole]

### Fixed

* Allow xpath 3.x gem [Thomas Walpole]
* Issue when drivers returned nil for `current_path` and a matcher was used with a Regexp [Thomas Walpole]
* Error message when visible element not found, but non-visible was [Andy Klimczak]

# Version 2.16.1
Release date: 2017-11-20

### Fixed

* Fix rack_test driver for rack_test 0.7.1/0.8.0 [Thomas Walpole]
* `accept_prompt` response text can contain quotes when using selenium with headless chrome [Thomas Walpole]

# Version 2.16.0
Release date: 2017-11-13

### Added

* Attempt to move element into view when selenium doesn't correctly do it - See PR #1917 [Thomas Walpole]
* `current_path` matchers will now autodetect path vs url based on string to be matched. Deprecates
  `:only_path` in favor of `:ignore_query` option [Thomas Walpole]
* Session#evaluate_async_script [Thomas Walpole]

### Fixed

* Default prompt value when using headless Chrome works correctly [Thomas Walpole]
* Support new modal error returned by selenium-webdriver 3.7 for W3C drivers [Thomas Walpole]
* Calling `respond_to?` on the object passed to `Capybara.configure` block - Issue #1935

# Version 2.15.4
Release date: 2017-10-07

### Fixed
*  Visiting an absolute URL shouldn't overwrite the port when no server or always_include_port=false - Issue #1921

# Version 2.15.3
Release date: 2017-10-03

### Fixed
*  Visiting '/' when Capybara.app_host has a trailing '/' - Issue #1918 [Thomas Walpole]

# Version 2.15.2
Release date: 2017-10-02

### Fixed

*  Include within scope description in element not found/ambiguous errors [Thomas Walpole]
*  Raise error when no activation block is passed to modal methods if using headless chrome [Thomas Walpole]
*  Don't retry element access when inspecting [Ivan Neverov]
*  Don't override a specified port (even if it is default port) in visited url [Thomas Walpole]

# Version 2.15.1

Release date: 2017-08-04

### Fixed

*  `attach_file` with no extension/MIME type when using the `:rack_test` driver [Thomas Walpole]

# Version 2.15.0

Release date: 2017-08-04

### Added

*  `sibling` and `ancestor` finders added [Thomas Walpole]
*  Added ability to pass options to registered servers when setting
*  Added basic built-in driver registrations `:selenium_chrome` and `:selenium_chrome_headless` [Thomas Walpole]
*  Add `and_then` to Capybara RSpec matchers which behaves like the previous `and` compounder. [Thomas Walpole]
*  Compound RSpec expectations with Capybara matchers now run both matchers inside a retry loop rather
   than waiting for one to pass/fail before checking the second.  Will make `#or` more performant and confirm
   both conditions are true "simultaneously" for `and`.  [Thomas Walpole]
   If you still want the
*  Default filter values are now included in error descriptions [Thomas Walpole]
*  Add `Session#refresh` [Thomas Walpole]
*  Loosened restrictions on where `Session#within_window` can be called from [Thomas Walpole]
*  Switched from `mime-types` dependency to `mini_mime` [Jason Frey]

# Version 2.14.4

Release date: 2017-06-27

### Fixed

* Fix retrieval of session_options for HaveSelector matcher descriptions - Issue #1883

# Version 2.14.3

Release date: 2017-06-15

### Fixed

* Minitest assertions now raise the correct error type - Issue #1879 [Thomas Walpole]
* Improve flexibility of detecting Chrome headless mode [Thomas Walpole]

# Version 2.14.2

Release date: 2017-06-09

### Fixed

* Workaround for system modals when using headless Chrome now works if the page changes

# Version 2.14.1

Release date: 2017-06-07

### Fixed

* Catch correct error when unexpected system modals are discovered in latest selenium [Thomas Walpole]
* Update default `puma` server registration to encourage it to run in single mode [Thomas Walpole]
* Suppress invalid element errors raised while lazily evaluating the results of `all` [Thomas Walpole]
* Added missing `with_selected` option to the :select selector to match `options`/`with_options` options - Issue #1865 [Bartosz Nowak]
* Workaround broken system modals when using selenium with headless Chrome

# Version 2.14.0

Release date: 2017-05-01

### Added

* "threadsafe" mode that allows per-session configuration
* `:type` filter added to the `:fillable_field` selector
* Proxy methods when using RSpec for `all`/`within` that call either the Capybara::DSL or RSpec matchers
  depending on arguments passed
* Support for the new errors in selenium-webdriver 3.4

### Fixed

* Element#inspect doesn't raise an error on obsolete elements
* Setting a contenteditable element with Selenium and Chrome 59
* Workaround a hang while setting the window size when using geckodriver 0.16 and Firefox 53
* Clicking on url with a blank href goes to the current url when using the RackTest driver

# Version 2.13.0

Release date: 2017-03-16

### Added

* Selenium driver supports returning element(s) from evaluate_script [Thomas Walpole]
* rack_test driver supports click on checkboxes and radio buttons to change their states [Thomas Walpole]
* Support RSpec equivalent assertions and expectations for MiniTest [Thomas Walpole]

### Fixed

* Editing of content editable children with selenium

# Version 2.12.1

Release date: 2017-02-16

### Fixed
*  Disable lazy Capybara::Results evaluation for JRuby due to ongoing issues

# Version 2.12.0

Release date: 2017-01-22

### Added

* Session#switch_to_frame for manually handling frame switching - Issue #1365 [Thomas Walpole]
* Session#within_frame now accepts a selector type (defaults to :frame) and locator [Thomas Walpole]
* Session#execute_script and Session#evaluate_script now accept optional arguments that will be passed to the JS function.  This may not be supported
  by all drivers, and the types of arguments that may be passed is limited.  If drivers opt to support this feature they should support passing page elements. [Thomas Walpole]
* :exact option for text and title matchers - Issue #1256 [Thomas Walpole]
* :exact_text option for selector finders/minders - Issue #1256 [Thomas Walpole]
* Capybara.exact_text setting that affects the text matchers and :text options passed to selector finders/matchers. Issue #1256 [Thomas Walpole]
* :make_visible option for #attach_file that allows for convenient changing of the CSS style of a file input element before attaching the file to it.  Requires driver
  support for passing page elements to Session#execute_script [Thomas Walpole]
* assert_all_selectors/assert_none_of_selectors assertions added
* :link selector (used by find_link/click_link) now supports finding hyperlink placeholders (no href attribute) when href: nil option is specified [Thomas Walpole]
* `within_element` as an alias of `within` due to RSpec collision

### Fixed

*  Fields inside a disabled fieldset are now correctly considered disabled - Issue #1816 [Thomas Walpole]
*  Lazy Capybara::Results evaluation enabled for JRuby 9.1.6.0+
*  A driver returning nil for #current_url won't raise an exception when calling #current_path [Dylan Reichstadt]
*  Support Ruby 2.4.0 unified Integer [Koichi ITO]
*  RackTest driver no longer modifies the text content of textarea elements in order to behave more like a real browser [Thomas Walpole]
*  TextQuery (assert_text/have_text/etc) now ignores errors when trying to generate more helpful errors messages so the original error isn't hidden [Thomas Walpole]

# Version 2.11.0

Release date: 2016-12-05

### Added

* Options for clearing session/local storage on reset added to the Selenium driver
* Window size changes wait for the size to stabilize
* Defined return value for most actions
* Ignore specific error when quitting selenium driver instance - Issue #1773 [Dylan Reichstadt, Thomas Walpole]
* Warn on selenium unknown errors rather than raising when quitting driver [Adam Pohorecki, Thomas Walpole]
* Capybara::Result#each now returns an `Enumerator` when called without a block - Issue #1777 [Thomas Walpole]

### Fixed

* Selenium driver with Chrome should support multiple file upload [Thomas Walpole]
* Fix visible: :hidden with :text option behavior [Thomas Walpole]

# Version 2.10.2

Release date: 2016-11-30

### Fixed

* App exceptions with multiple parameter initializers now re-raised correctly - Issue #1785 [Michael Lutsiuk]
* Use Addressable::URI when parsing current_path since it's more lenient of technically invalid URLs - Issue #1801 [Marcos Duque, Thomas Walpole]

# Version 2.10.1

Release date: 2016-10-08

### Fixed
* App errors are now correctly raised with the explanatory cause in JRuby [Thomas Walpole]
* Capybara::Result optimization disabled in JRuby due to issue with lazy enumerator evaluation [Thomas Walpole]
  See: https://github.com/jruby/jruby/issues/4212

# Version 2.10.0

Release date: 2016-10-05

### Added

* Select `<button>` elements with descendant images with `alt` attributes matching the locator [Ian Lesperance]
* Locator string is optional in selector based matchers [Thomas Walpole]
* Selectors can specify their default visible setting [Thomas Walpole]
* Selector based finders and matchers can be passed a block to filter the results within the retry behavior [Thomas Walpole]

# Version 2.9.2

Release date: 2016-09-29

### Fixed

* :label built-in selector finds nested label/control by control id if the label has no 'for' attribute [Thomas Walpole]
* Warning issued if an unknown selector type is specified [Thomas Walpole]

# Version 2.9.1

Release date: 2016-09-23

### Fixed

* allow_label_click option did not work in some cases with Poltergeist - Issue #1762 [Thomas Walpole]
* matches_selector? should have access to all of a selectors options except the count options [Thomas Walpole]

# Version 2.9.0

Release date: 2016-09-19

### Fixed

* Issue with rack-test driver and obsolete mime-types when using `#attach_file` - Issue #1756 [Thomas Walpole]

### Added

* `:class` option to many of the built-in selectors [Thomas Walpole]
* Removed need to specify value when creating `:boolean` filter type in custom selectors [Thomas Walpole]
* Filters can now be implemented through the XPath/CSS expressions in custom selectors [Thomas Walpole]
* `Element#matches_xpath?` and `Element#matches_css?` [Thomas Walpole]

# Version 2.8.1

Release date: 2016-08-25

### Fixed

* Fixed error message from have_text when text is not found but contains regex special characters [Ryunosuke Sato]
* Warn when :exact option is passed that has no effect [Thomas Walpole]

# Version 2.8.0

Release date: 2016-08-16

### Fixed

* Issue with modals present when closing the page using selenium - Issue #1696 [Jonas Nicklas, Thomas Walpole]
* Server errors raised in test code have the cause set to an explanatory exception
  in rubies that support Exception#cause rather than a confusing ExpectationNotMet - Issue #1719 [Thomas Walpole]
* background/given/given! RSpec aliases will work if RSpec config.shared_context_metadata_behavior == :apply_to_host_groups [Thomas Walpole]
* Fixed setting of unexpectedAlertError now that Selenium will be freezing the Capabilities::DEFAULTS [Thomas Walpole]

### Added

* 'check', 'uncheck', and 'choose' can now optionally click the associated label if the checkbox/radio button is not visible [Thomas Walpole]
* Raise error if Capybara.app_host/default_host are specified incorrectly [Thomas Walpole]
* Capybara::Selector::FilterSet allows for sharing filter definitions between selectors [Thomas Walpole]
* Remove need to pass nil locator in most node actions when locator is not needed [Thomas Walpole]
* New frames API for drivers - Issue #1365 [Thomas Walpole]
* Deprecated Element#parent in favor of Element#query_scope to better indicate what it is [Thomas Walpole]
* Improved error messages for have_text matcher [Alex Chaffee, Thomas Walpole]
* The `:with` option for the field selector now accepts a regular expression for matching the field value [Uwe Kubosch]
* Support matching on aria-label attribute when finding fields/links/buttons - Issue #1528 [Thomas Walpole]
* Optimize Capybara::Result to only apply fields as necessary in common use-case of `.all[idx]` [Thomas Walpole]

# Version 2.7.1

Release date: 2016-05-01

### Fixed

* Issue where within_Frame would fail with Selenium if the frame is removed from within itself [Thomas Walpole]
* Reset sessions in reverse order so sessions with active servers are reset last - Issue #1692 [Jonas Nicklas, Thomas Walpole]

# Version 2.7.0

Release date: 2016-04-07

### Fixed

* Element#visible?/checked?/disabled?/selected? Now return boolean as expected when using the rack_test driver [Thomas Walpole]
* The rack_test driver now considers \<input type="hidden"> elements as non-visible [Thomas Walpole]
* A nil locator passed to the built-in html type selectors now behaves consistently, and finds elements of the expected types [Thomas Walpole]
* Capybara::Server now searches for available ports on the same interface it binds to [Aaron Stone]
* Selenium Driver handles system modals that appear when page is unloading [Thomas Walpole]
* Warning output if unused parameters are passed to a selector query [Thomas Walpole]

### Added

* Capybara now waits for requests to Capybaras server to complete while resetting the session [John Hawthorn, Thomas Walpole]
* Capybara.reuse_server option to allow disabling of sharing server instance between sessions [Thomas Walpole]
* :multiple filter added to relevant selectors [Thomas Walpole]
* Provided server registrations for :webrick and :puma. Capybara.server = :puma for testing with Rails 5 [Thomas Walpole]
* Deprecate passing a block to Capybara::server user Capybara::register_server instead [Thomas Walpole]
* :option selector supports :selected and :disabled filters [Thomas Walpole]
* Element#matches_selector? and associated matchers (match_selector, match_css, etc) for comparing an element to a selector [Thomas Walpole]
* Deprecated Driver#browser_initialized? - Driver#reset! is required to be synchronous [Jonas Nicklas, Thomas Walpole]
* Deprecated Capybara.save_and_open_page_path in favor of Capybara.save_path with slightly different behavior when using relative paths with
  save_page/save_screenshot [Thomas Walpole]
* :label selector [Thomas Walpole]

# Version 2.6.2

Release date: 2016-01-27

### Fixed

* support for more than just addressable 2.4.0 [Thomas Walpole]

# Version 2.6.1

Release date: 2016-01-27

### Fixed

* Add missing require for addressable [Jorge Bejar]

# Version 2.6.0

Relase date: 2016-01-17

### Fixed

* Fixed path escaping issue with current_path matchers [Thomas Walpole, Luke Rollans] (Issue #1611)
* Fixed circular require [David Rodríguez]
* Capybara::RackTest::Form no longer overrides Object#method [David Rodriguez]
* options and with_options filter for :select selector have more intuitive visibility behavior [Nathan]
* Test for nested modal API method support [Thomas Walpole]


### Added

* Capybara.modify_selector [Thomas Walpole]
* xfeature and ffeature aliases added when using RSpec [Filip Bartuzi]
* Selenium driver supports a :clear option to #set to handle different strategies for clearing a field [Thomas Walpole]
* Support the use of rack 2.0 with the rack_test driver [Travis Grathwell, Thomas Walpole]
* Disabled option for default selectors now supports true, false, or :all [Jillian Rosile, Thomas Walpole]
* Modal API methods now default wait time to Capybara.default_max_wait_time [Thomas Walpole]

# Version 2.5.0

Release date: 2015-08-25

### Fixed

* Error message now raised correctly when invalid options passed to 'have_text'/'have_content' [Thomas Walpole]
* Rack-test driver correctly gets document title when elements on the page have nested title elements (SVG) [Thomas Walpole]
* 'save_page' no longer errors when using Capybara.asset_host if the page has no \<head> element [Travis Grathwell]
* rack-test driver will ignore clicks on links with href starting with '#' or 'javascript:'

### Added

* has_current_path? and associated asserts/matchers added [Thomas Walpole]
* Implement Node#path in selenium driver [Soutaro Matsumoto]
* 'using_session' is now nestable [Thomas Walpole]
* 'switch_to_window' will now use waiting behavior for a matching window to appear [Thomas Walpole]
* Warning when attempting to select a disabled option
* Capybara matchers are now available in RSpec view specs by default [Joshua Clayton]
* 'have_link' and 'click_link' now accept Regexp for href matching [Yaniv Savir]
* 'find_all' as an alias of 'all' due to collision with RSpec
* Capybara.wait_on_first_by_default setting (default is false)
  If set to true 'first' will use Capybaras waiting behavior to wait for at least one element to appear by default
* Capybara waiting behavior uses the monotonic clock if supported to ease restrictions on freezing time in tests [Dmitry Maksyoma, Thomas Walpole]
* Capybara.server_errors setting that allows to configure what type of errors will be raised from the server thread [Thomas Walpole]
* Node#send_keys to allow for sending keypresses directly to elements [Thomas Walpole]
* 'formmethod' attribute support in RackTest driver [Emilia Andrzejewska]
* Clear field using backspaces in Selenium driver by using `:fill_options => { :clear => :backspace }` [Joe Lencioni]

### Deprecated

* Capybara.default_wait_time deprecated in favor of Capybara.default_max_wait_time to more clearly explain its purpose [Paul Pettengill]

# Version 2.4.4

Release date: 2014-10-13

### Fixed

* Test for visit behavior updated [Phil Baker]
* Removed concurrency prevention in favor of a note in the README - due to load order issues

# Version 2.4.3

Relase date: 2014-09-21

### Fixed

* Update concurrency prevention to match Rails 4.2 behavior

# Version 2.4.2

Release date: 2014-09-20

### Fixed

* Prevent concurrency issue when testing Rails app with default test environment [Thomas Walpole]
* Tags for windows API tests fixed [Dmitry Vorotilin]
* Documentation Fixes [Andrey Botalov]
* Always convert visit url to string, fixes issue with visit when always_include_port was enabled [Jake Goulding]
* Check correct rspec version before including ::RSpec::Matchers::Composable in Capybara RSpec matchers [Thomas Walpole, Justin Ko]

# Version 2.4.1

Release date: 2014-07-03

### Added

* 'assert_text', 'assert_no_text', 'assert_title', 'assert_no_title' methods added [Andrey Botalov]
* have_title matcher now supports :wait option [Andrey Botalov]
* More descriptive have_text error messages [Andrey Botalov]
* New modal API ('accept_alert', 'accept_confirm', 'dismiss_confirm', 'accept_prompt', 'dismiss_prompt') - [Mike Pack, Thomas Walpole]
* Warning when attempting to set contents of a readonly element
* Suport for and/or compounding of Capybara's RSpec matchers for RSpec 3 [Thomas Walpole]
* :fill_options option for 'fill_in' method that propagates to 'set' to allow for driver specific modification of how fields are filled in [Gabriel Sobrinho, Thomas Walpole]
* Improved selector/filter description in failure messages [Thomas Walpole]

### Fixed

* HaveText error message now shows the text checked all the time
* RackTest driver no longer attempts to follow an anchor tag without an href attribute
* Warnings under RSpec 3
* Handle URI schemes like about: correctly [Andrey Botalov]
* RSpecs expose_dsl_globally option is now followed [Myron Marston, Thomas Walpole]

# Version 2.3.0

Release date: 2014-06-02

### Added

* New window management API [Andrey Botalov]
* Speed improvement for visible text detection in RackTest [Thomas Walpole]
  Thanks to Phillipe Creux for instigating this
* RSpec 3 compatability
* 'save_and_open_screenshot' functionality [Greg Lazarev]
* Server errors raised on visit and synchronize [Jonas Nicklas]

### Fixed

* CSSHandlers now derives from BasicObject so globally included functions (concat, etc) shouldn't cause issues [Thomas Walpole]
* touched reset after session is reset [lesliepc16]

# Version 2.2.1

Release date: 2014-01-06

### Fixed

* Reverted a change in 2.2.0 which navigates to an empty file on `reset`.
  Capybara, now visits `about:blank` like it did before. [Jonas Nicklas]

# Version 2.2.0

Release date: 2013-11-21

### Added

* Add `go_back` and `go_forward` methods. [Vasiliy Ermolovich]
* Support RSpec 3 [Thomas Holmes]
* `has_button?`, `has_checked_field?` and `has_unchecked_field?` accept
  options, like other matchers. [Carol Nichols]
* The `assert_selector` and `has_text?` methods now support the `:wait` option
  [Vasiliy Ermolovich]
* RackTest's visible? method now checks for the HTML5 `hidden` attribute.
* Results from `#all` now delegate the `sample` method. [Phil Lee]
* The `set` method now works for contenteditable attributes under Selenium.
  [Jon Rowe]
* radio buttons and check boxes can be filtered by option value, useful when
  selecting by name [Jonas Nicklas]
* feature blocks can be nested within other feature blocks in RSpec tests
  [Travis Gaff]

### Fixed

* Fixed race conditions causing stale element errors when filtering by text.
  [Jonas Nicklas]
* Resetting the page is now synchronous and navigates to an empty HTML file,
  instead of `about:blank`, fixing hanging issues in JRuby. [Jonas Nicklas]
* Fixed cookies not being set when path is blank under RackTest [Thomas Walpole]
* Clearing fields now correctly causes change events [Jonas Nicklas]
* Navigating to an absolute URI without trailing slash now works as expected
  under RackTest [Jonas Nicklas]
* Checkboxes without assigned value default to `on` under RackTest [Nigel Sheridan-Smith]
* Clicks on buttons with no form associated with them are ignored in RackTest
  instead of raising an obscure exception. [Thomas Walpole]
* execute_script is now a session method [Andrey Botalov]
* Nesting `within_window` and `within_frame` inside `within` resets the scope
  so that they behave like a user would expect [Thomas Walpole]
* Improve handling of newlines in textareas [Thomas Walpole]
* `Capybara::Result` delegates its inspect method, so as not to confuse users
  [Sam Rawlins]
* save_page always returns a full path, fixes problems with Launchy [Jonas Nicklas]
* Selenium driver's `quit` method does nothing when browser hasn't been loaded
  [randoum]
* Capybara's WEBRick server now propertly respects the server_host option
  [Dmitry Vorotilin]
* gemspec now includes license information [Jonas Nicklas]

# Version 2.1.0

Release date: 2013-04-09

### Changed

* Hard version requirement on Ruby >= 1.9.3. Capybara will no longer install
  on 1.8.7. [Felix Schäfer]
* Capybara no longer depends on the `selenium-webdriver` gem. Add it to
  your Gemfile if you wish to use the Selenium driver. [Jonas Nicklas]
* `Capybara.ignore_hidden_elements` defaults to `true`. [Jonas Nicklas]
* In case of multiple matches `smart` matching is used by default. Set
  `Capybara.match = :one` to revert to old behaviour. [Jonas Nicklas].
* Options in select boxes use smart matching and no longer need to match
  exactly. Set `Capybara.exact_options = false` to revert to old behaviour.
  [Jonas Nicklas].
* Visibility of text depends on `Capybara.ignore_hidden_elements` instead of
  always returning only visible text. Set `Capybara.visible_text_only = true`
  to revert to old behaviour. [Jonas Nicklas]
* Cucumber cleans up session after scenario instead. This is consistent with
  RSpec and makes more sense, since we raise server errors in `reset!`.
  [Jonas Nicklas]

### Added

* All actions (`click_link`, `fill_in`, etc...) and finders now take an options
  hash, which is passed through to `find`. [Jonas Nicklas]
* CSS selectors are sent straight through to driver instead of being converted
  to XPath first. Enables the use of some pseudo selectors, such as `invalid`
  in some drivers. [Thomas Walpole]
* `Capybara.asset_host` option, which inserts a `base` tag into the page on
  `save_and_open_page`, eases debugging with the Rails asset pipeline.
  [Steve Hull]
* `exact` option, can specify whether to match substrings or entire text.
  [Jonas Nicklas]
* `match` option, can specify behaviour in case of multiple matches.
  [Jonas Nicklas]
* `wait` option, can specify how long to wait for a given action/finder.
  [Jonas Nicklas]
* Config option which disables bubbling of errors raised inside server.
  [Jonas Nicklas]
* `text` now takes a parameter which makes it possible to return either all
  text or only visible text. The default depends on
  `Capybara.ignore_hidden_elements`. `Capybara.visible_text_only` option is
  available for compatibility. [Jonas Nicklas]
* `has_content?` and `has_text?` now take the same count options as `has_selector?`
  [Andrey Botalov]
* `current_scope` is now public API, returns the current element when `within`
  is used. [Martijn Walraven]
* `find("input").disabled?` returns true if a node is disabled. [Ben Lovell]
* Find disabled fields and buttons with `:disabled => false`. [Jonas Nicklas]
* `find("input").hover` moves the mouse to the element in supported drivers.
  [Thomas Walpole]
* RackTest driver now support `form` attribute on form elements.
  [Thomas Walpole]
* `page.title` returns the page title. [Terry Progetto]
* `has_title?` matcher to assert on page title. [Jonas Nicklas]
* The gem is now signed with a certicficate. The public key is available in the
  repo. [Jonas Nicklas]
* `:select` and `:textarea` are valid options for the `:type` filter on `find_field`
  and `has_field?`. [Yann Plancqueel]

### Fixed

* Fixed race conditions when synchronizing across multiple nodes [Jonas Nicklas]
* Fixed race conditions in deeply nested selectors [Jonas Nicklas]
* Fix issue with `within_frame`, where selecting multiple nested frames didn't
  work as intended. [Thomas Walpole]
* RackTest no longer fills in readonly textareas. [Thomas Walpole]
* Don't use autoload to load files, require them directly instead. [Jonas Nicklas]
* Rescue weird exceptions when booting server [John Wilger]
* Non strings are now properly cast when using the maxlength attribute [Jonas Nicklas]

# Version 2.0.3

Release date: 2013-03-26

* Check against Rails version fixed to work with Rails' master branch now returning
  a Gem::Version [Jonas Nicklas]
* Use posix character class for whitespace replace, solves various encoding
  problems on Ruby 2.0.0 and JRuby. [Ben Cates]

# Version 2.0.2

Release date: 2012-12-31

### Changed

* Capybara no longer uses thin as a server if it is available, due to thread
  safety issues. Now Capybara always defaults to WEBrick. [Jonas Nicklas]

### Fixed

* Suppress several warnings [Kouhei Sutou]
* Fix default host becoming nil [Brian Cardarella]
* Fix regression in 2.0.1 which caused node comparisons with non node objects
  to throw an exception [Kouhei Sotou]
* A few changes to the specs, only relevant to driver authors [Jonas Nicklas]
* Encoding error under JRuby [Piotr Krawiec]
* Ruby 2 encoding fix [Murahashi Sanemat Kenichi]
* Catch correct exception on server timeout [Jonathan del Strother]

# Version 2.0.1

Release date: 2012-12-21

### Changed

* Move the RackTest driver override with the `:respect_data_method` option
  enabled from capybara/rspec to capybara/rails, so that it is enabled in
  Rails projects that don't use RSpec. [Carlos Antonio da Silva]
* `source` is now an alias for `html`. RackTest no longer returns modifications
  to `html`. This basically codifies the behaviour which we've had for a while
  anyway, and should have minimal impact for end users. For driver authors, it
  means that they only have to implement `html`, and not `source`. [Jonas
  Nicklas]

### Fixed

* Visiting relative URLs when `app_host` is set and no server is running works
  as expected. [Jonas Nicklas]
* `fill_in` works properly under Selenium again when the caret is not at the
  end of the field before the method is called. [Douwe Maan, Jonas Nicklas, Jari
  Bakken]
* `attach_file` can once again be given a Pathname [Jake Goulding]

# Version 2.0.0

Release date: 2012-11-05

### Changed

* Dropped official support for Ruby 1.8.x. [Jonas Nicklas]
* `respect_data_method` default to `false` for the RackTest driver in non-rails
  applications. That means that Capybara no longer picks up `data-method="post"`
  et. al. from links by default when you haven't required capybara/rails
  [Jonas Nicklas]
* `find` now raises an error if more than one element was found. Since `find` is
  used by most actions, like `click_link` under the surface, this means that all
  actions need to unambiguous in the future. [Jonas Nicklas]
* All methods which find or manipulate fields or buttons now ignore them when
  they are disabled. [Jonas Nicklas]
* Can no longer find elements by id via `find(:foo)`, use `find("#foo")` or
  `find_by_id("foo")` instead. [Jonas Nicklas]
* `Element#text` on RackTest now only returns visible text and normalizes
  (strips) whitespace, as with Selenium [Mark Dodwell, Jo Liss]
* `has_content?` now checks the text value returned by `Element#text`, as opposed to
  querying the DOM. Which means it does not match hidden text.
  [Ryan Montgomery, Mark Dodwell, Jo Liss]
* #394: `#body` now returns the unmodified source (like `#source`), not the current
  state of the DOM (like `#html`), by popular request [Jonas Nicklas]
* `Node#all` no longer returns an array, but rather an enumerable `Capybara::Result`
  [Jonas Nicklas]
* The arguments to `select` and `unselect` needs to be the exact text of an option
  in a select box, substrings are no longer allowed [Jonas Nicklas]
* The `options` option to `has_select?` must match the exact set of options. Use
  `with_options` for the old behaviour. [Gonzalo Rodriguez]
* The `selected` option to `has_select?` must match all selected options for multiple
  selects. [Gonzalo Rodriguez]
* Various internals for running driver specs, this should only affect driver authors
  [Jonas Nicklas]
* Rename `Driver#body` to `Driver#html` (relevant only for driver authors) [Jo
  Liss]

### Removed

* No longer possible to specify `failure_message` for custom selectors. [Jonas Nicklas]
* #589: `Capybara.server_boot_timeout` has been removed in favor of a higher
  (60-second) hard-coded timeout [Jo Liss]
* `Capybara.prefer_visible_elements` has been removed, as it is no longer needed
  with the changed find semantics [Jonas Nicklas]
* `Node#wait_until` and `Session#wait_until` have been removed. See `Node#synchronize`
  for an alternative [Jonas Nicklas]
* `Capybara.timeout` has been removed [Jonas Nicklas]
* The `:resynchronize` option has been removed from the Selenium driver [Jonas Nicklas]
* The `rows` option to `has_table?` has been removed without replacement.
  [Jonas Nicklas]

### Added

* Much improved error message [Jonas Nicklas]
* Errors from inside the session for apps running in a server are raised when
  session is reset [James Tucker, Jonas Nicklas]
* A ton of new selectors built in out of the box, like `field`, `link`, `button`,
  etc... [Adam McCrea, Jonas Nicklas]
* `has_text?` has been added as an alias for `has_content?` [Jonas Nicklas]
* Add `Capybara.server_host` option (default: 127.0.0.1) [David Balatero]
* Add `:type` option for `page.has_field?` [Gonzalo Rodríguez]
* Custom matchers can now be specified in CSS in addition to XPath [Jonas Nicklas]
* `Node#synchronize` method to rerun a block of code if certain errors are raised
  [Jonas Nicklas]
* `Capybara.always_include_port` config option always includes the server port in
  URLs when using `visit`. Facilitates testing different domain names. [Douwe Maan]
* Redirect limit for RackTest driver is configurable [Josh Lane]
* Server port can be manually specified during initialization of server.
  [Jonas Nicklas, John Wilger]
* `has_content?` and `has_text?` can be given a regular expression [Vasiliy Ermolovich]
* Multiple files can be uploaded with `attach_file` [Jarl Friis]

### Fixed

* Nodes found via `all` are no longer reloaded. This fixes weird quirks where
  nodes would seemingly randomly replace themselves with other nodes [Jonas Nicklas]
* Session is only reset if it has been modified, dramatically improves performance if
  only part of the test suite runs Capybara. [Jonas Nicklas]
* Test suite now passes on Ruby 1.8 [Jo Liss]
* #565: `require 'capybara/dsl'` is no longer necessary [Jo Liss]
* `Rack::Test` now respects ports when changing hosts [Jo Liss]
* #603: `Rack::Test` now preserves the original referer URL when following a
  redirect [Rob van Dijk]
* Rack::Test now does not send a referer when calling `visit` multiple times
  [Jo Liss]
* Exceptions during server boot now propagate to main thread [James Tucker]
* RSpec integration now cleans up before the test instead of after [Darwin]
* If `respect_data_method` is true, the data-method attribute can be capitalized
  [Marco Antonio]
* Rack app boot timing out raises an error as opposed to just logging to STDOUT
  [Adrian Irving-Beer]
* `#source` returns an empty string instead of nil if no pages have been visited
  [Jonas Nicklas]
* Ignore first leading newline in textareas in RackTest [Vitalii Khustochka]
* `within_frame` returns the value of the given block [Alistair Hutchison]
* Running `Node.set` on text fields will not trigger more than one change event
  [Andrew Kasper]
* Throw an error when an option is given to a finder method, like `all` or
  `has_selector?` which Capybara doesn't understand [Jonas Nicklas]
* Two references to the node now register as equal when comparing them with `==`
  [Jonas Nicklas]
* `has_text` (`has_content`) now accepts non-string arguments, like numbers.
  [Jo Liss]
* `has_text` and `text` now correctly normalize Unicode whitespace, such as
  `&nbsp;`. [Jo Liss]
* RackTest allows protocol relative URLs [Jonas Nicklas]
* Arguments are cast to string where necessary, so that e.g. `click_link(:foo)` works
  as expected. [Jonas Nicklas]
* `:count => 0` now works as expected [Jarl Friis]
* Fixed race conditions on negative assertions when removing nodes [Jonas Nicklas]

# Version 1.1.4

Release date: 2012-11-28

### Fixed

* Fix more race conditions on negative assertions. [Jonas Nicklas]

# Version 1.1.3

Release date: 2012-10-30

### Fixed:

* RackTest driver ignores leading newline in textareas, this is consistent with
  the spec and how browsers behave. [Vitalii Khustochka]
* Nodes found via `all` and `first` are never reloaded. This fixes issues where
  a node would sometimes magically turn into a completely different node.
  [Jonas Nicklas]
* Fix race conditions on negative assertions. This fixes issues where removing
  an element and asserting on its non existence could cause
  StaleElementReferenceError and similar to be thrown. [Jonas Nicklas]
* Options are no longer lost when reloading elements. This fixes issues where
  reloading an element would cause a non-matching element to be found, because
  options to `find` were ignored. [Jonas Nicklas]

# Version 1.1.2

Release date: 2011-11-15

### Fixed

* #541: Make attach_file work with selenium-webdriver >=2.12 [Jonas Nicklas]

# Version 1.1.0

Release date: 2011-09-02

### Fixed

* Sensible inspect for Capybara::Session [Jo Liss]
* Fix headers and host on redirect [Matt Colyer, Jonas Nicklas, Kim Burgestrand]
* using_driver now restores the old driver instead of reverting to the default [Carol Nichols]
* Errors when following links relative to the root path under rack-test [Jonas Nicklas, Kim Burgestrand]
* Make sure exit codes are propagated properly [Edgar Beigarts]

### Changed

* resynchronization is off by default under Selenium

### Added

* Elements are automatically reloaded (including parents) during wait [Jonas Nicklas]
* Rescue driver specific element errors, such as the dreaded ObsoleteElementError and retry [Jonas Nicklas]
* Raise an error if something has frozen time [Jonas Nicklas]
* Allow within to take a node instead of a selector [Peter Williams]
* Using wait_time_time to change wait time for a block of code [Jonas Nicklas, Kim Burgestrand]
* Option for rack-test driver to disable data-method hack [Jonas Nicklas, Kim Burgestrand]

# Version 1.0.1

Release date: 2011-08-12

### Fixed

* Dependend on selenium-webdriver ~>2.0 and fix deprecations [Thomas Walpole, Jo Liss]
* Depend on Launch 2.0 [Jeremy Hinegardner]
* Rack-Test ignores fill in on fields with maxlength=""

# Version 1.0.0

Release date: 2011-06-14

### Added

* Added DSL for acceptance tests, inspired by Luismi Cavallé's Steak [Luismi Cavalle and Jonas Nicklas]
* Selenium driver automatically waits for AJAX requests to finish [mgiambalvo, Nicklas Ramhöj and Jonas Nicklas]
* Support for switching between multiple named sessions [Tristan Dunn]
* failure_message can be specified for Selectors [Jonas Nicklas]
* RSpec matchers [David Chelimsky and Jonas Nicklas]
* Added save_page to save tempfile without opening in browser [Jeff Kreeftmeijer]
* Cucumber now switches automatically to a registered driver if the tag matches the name [Jonas Nicklas]
* Added Session#text [Jonas Nicklas and Scott Cytacki]
* Added Session#html as an alias for Session#body [Jo Liss]
* Added Session#current_host method [Jonas Nicklas]
* Buttons can now be clicked by title [Javier Martin]
* :headers option for RackTest driver to set custom HTTP headers [Jonas Nicklas]

### Removed

* Culerity and Celerity drivers have been removed and split into separate gems [Gabriel Sobrinho]

### Deprecated

* `include Capybara` has been deprecated in favour of `include Capybara::DSL` [Jonas Nicklas]

### Changed

* Rack test driver class has been renamed from Capybara::Driver::RackTest to Capybara::RackTest::Driver [Jonas Nicklas]
* Selenium driver class has been renamed from Capybara::Driver::Selenium to Capybara::Selenium::Driver [Jonas Nicklas]
* Capybara now prefers visible elements over hidden elements, disable by setting Capybara.prefer_visible_elements = false [Jonas Nicklas and Nicklas Ramhöj]
* For RSpec, :type => :request is now supported (and preferred over :acceptance) [Jo Liss]
* Selenium driver tried to wait for AJAX requests to finish before proceeding [Jonas Nicklas and Nicklas Ramhöj]
* Session no longer uses method missing, uses explicit delegates instead [Jonas Nicklas]

### Fixed

* The Rack::Test driver now respects maxlength on text fields [Guilherme Carvalho]
* Allow for more than one save_and_open_page call per second [Jo Liss]
* Automatically convert options to :count, :minimum, :maximum, etc. to integers [Keith Marcum]
* Rack::Test driver honours maxlength on input fields [Guilherme Carvalho]
* Rack::Test now works as expected with domains and subdomains [Jonas Nicklas]
* Session is reset more thoroughly between tests. [Jonas Nicklas]
* Raise error when uploading non-existent file [Jonas Nicklas]
* Rack response body should respond to #each [Piotr Sarnacki]
* Deprecation warnings with selenium webdriver 0.2.0 [Aaron Gibraltar]
* Selenium Chrome no longer YELLS tagname [Carl Jackson & David W. Frank]
* Capybara no longer strips encoding before sending to Rack [Jonas Nicklas]
* Improve handling of relative URLs [John Barton]
* Readd and fix build_rack_mock_session [Jonas Nicklas, Jon Leighton]

# Version 0.4.1

Release date: 2011-01-21

### Added

* New click_on alias for click_link_or_button, shorter yet unambiguous. [Jonas Nicklas]
* Finders now accept :visible => false which will find all elements regardless of Capybara.ignore_hidden_elements [Jonas Nicklas]
* Configure how the server is started via Capybara.server { |app, port| ... }. [John Firebough]
* Added :between, :maximum and :minimum options to has_selector and friends [James B. Byrne]
* New Capybara.string util function which allows matchers on arbitrary strings, mostly for helper and view specs [David Chelimsky and Jonas Nicklas]
* Server boot timeout is now configurable, via Capybara.server_boot_timeout [Adam Cigánek]
* Built in support for RSpec [Jonas Nicklas]
* Capybara.using_driver to switch to a different driver temporarily [Jeff Kreeftmeijer]
* Added Session#first which is somewhat speedier than Session#all, use it internally for speed boost [John Firebaugh]

### Changed

* Session#within now accepts the same arguments as other finders, like Session#all and Session#find [Jonas Nicklas]

### Removed

* All deprecations from 0.4.0 have been removed. [Jonas Nicklas]

### Fixed

* Don't mangle URLs in save_and_open_page when using self-closing tags [Adam Spiers]
* Catch correct error when server boot times out [Jonas Nicklas]
* Celerity driver now properly passes through options, making it configurable [Jonas Nicklas]
* Better implementation of attributes in C[ue]lerity, should fix issues with attributes with strange names [Jonas Nicklas]
* Session#find no longer swallows errors [Jonas Nicklas]
* Fix problems with multiple file inputs [Philip Arndt]
* Submit multipart forms as multipart under rack-test even if they contain no files [Ryan Kinderman]
* Matchers like has_select? and has_checked_field? now work with dynamically changed values [John Firebaugh]
* Preserve order of rack params [Joel Chippindale]
* RackTest#reset! is more thorough [Joel Chippindale]

# Version 0.4.0

Release date: 2010-10-22

### Changed

* The Selector API was changed slightly, use Capybara.add_selector, see README

### Fixed

* Celerity driver is registered properly
* has_selector? and has_no_selector? added to DSL
* Multiple selects return correct values under C[cu]lerity
* Naked query strings are handled correctly by rack-test

# Version 0.4.0.rc

Release date: 2010-10-12

### Changed

* within and find/locate now follow the XPath spec in that //foo finds all nodes in the document, instead of
  only for the context node. See this post for details: http://groups.google.com/group/ruby-capybara/browse_thread/thread/b129067979df21b3
* within now executes within the first found instance of the selector, not in all of them
* find now waits for AJAX requests and raises an exception when the element is not found (same as locate used to do)
* The default selector is now CSS, not XPath

### Deprecated

* Session#click has been renamed click_link_or_button and the old click has been deprecated
* Node#node has been renamed native
* Node#locate is deprecated in favor of Node#find, which now behaves identically
* Session#drag is deprecated, please use Node#drag_to(other_node) instead

### Added

* Pretty much everything is properly documented now
* It's now possible to call all session methods on nodes, like `find('#foo').fill_in(...)`
* Custom selectors can be added with Capybara::Selector.add
* The :id selector is added by default, use it lile `find(:id, 'foo')` or `find(:foo)`
* Added Node#has_selector? so any kind of selector can be queried.
* Added Capybara.configure for less wordy configuration
* Added within_window to switch between different windows (currently Selenium only)
* Capybara.server_port to provide a fixed port if wanted (defaults to automatic selection)

### Fixed

* CSS selectors with multiple selectors, such as "h1, h2" now work correctly
* Port is automatically assigned instead of guessing
* Strip encodings in rack-test, no more warnings!
* RackTest no longer submits disabled fields
* Servers no longer output annoying debug information when started
* TCP port selection is left to Ruby to decide, no more port guessing
* Select boxes now return option value instead of text if present
* The default has been changed from localhost to 127.0.0.1, should fix some obscure selenium bugs
* RackTest now supports complex field names, such as foo[bar][][baz]

# Version 0.3.9

Release date: 2010-07-03

### Added

* status_code which returns the HTTP status code of the last response (no Selenium!)
* Capybara.save_and_open_page to store tempfiles
* RackTest and Culerity drivers now clean up after themselves properly

### Fixed

* When no rack app is set and the app is called, a more descriptive error is raised
* select now works with optgroups
* Don't submit image buttons unless they were clicked under rack-test
* Support custom field types under Selenium
* Support input fields without a type, treat them as though they were text fields
* Redirect now throws an error after 5 redirects, as per RFC
* Selenium now properly raises an error when Node#trigger is called
* Node#value now returns the correct value for textareas under rack-test

# Version 0.3.8

Release date: 2010-05-12

### Added

* Within_frame method to execute a block of code within a particular iframe (Selenium only!)

### Fixed

* Single quotes are properly escaped with `select` under rack-test and Selenium.
* The :text option for searches now escapes regexp special characters when a string is given.
* Selenium now correctly checks already checked checkboxes (same with uncheck)
* Timing issue which caused Selenium to hang under certain circumstances.
* Selenium now resolves attributes even if they are given as a Symbol

# Version 0.3.7

Release date: 2010-04-09

This is a drop in compatible maintenance release. It's mostly
important for driver authors.

### Added

* RackTest scans for data-method which rails3 uses to change the request method

### Fixed

* Don't hang when starting server on Windoze

### Changed

* The driver and session specs are now located inside lib! Driver authors can simply require them.

# Version 0.3.6

Release date: 2010-03-22

This is a maintenance release with minor bug fixes, should be
drop in compatible.

### Added

* It's now possible to load in external drivers

### Fixed

* has_content? ignores whitespace
* Trigger events when choosing radios and checking checkboxes under Selenium
* Make Capybara.app totally optional when running without server
* Changed fallback host so it matches the one set up by Rails' integration tests

# Version 0.3.5

Release date: 2010-02-26

This is a mostly backwards compatible release, it does break
the API in some minor places, which should hopefully not affect
too many users, please read the release notes carefully!

### Breaking

* Relative searching in a node (e.g. find('//p').all('//a')) will now follow XPath standard
  this means that if you want to find descendant nodes only, you'll need to prefix a dot!
* `visit` now accepts fully qualified URLs for drivers that support it.
* Capybara will always try to run a rack server, unless you set Capybara.run_sever = false

### Changed

* thin is preferred over mongrel and webrick, since it is Ruby 1.9 compatible
* click_button and click will find <input type="button">, clicking them does nothing in RackTest

### Added

* Much improved error messages in a multitude of places
* More semantic page querying with has_link?, has_button?, etc...
* Option to ignore hidden elements when querying and interacting with the page
* Support for multiple selects

### Fixed

* find_by_id is no longer broken
* clicking links where the image's alt attribute contains the text is now possible
* within_fieldset and within_table work when the default selector is CSS
* boolean attributes work the same across drivers (return true/false)
