# MetaInpector Changelog

## [Changes in 5.13.0](https://github.com/jaimeiniesta/metainspector/compare/v5.12.1...v5.13.0)

* Remove support for #feed that was deprecated in 5.9
* Add support for Ruby 3.1

## [Changes in 5.12.1](https://github.com/jaimeiniesta/metainspector/compare/v5.12.0...v5.12.1)

* Update dependencies: rubocop, nokogiri

## [Changes in 5.12.0](https://github.com/jaimeiniesta/metainspector/compare/v5.11.2...v5.12.0)

* Support Ruby 3.0

## [Changes in 5.11.2](https://github.com/jaimeiniesta/metainspector/compare/v5.11.1...v5.11.2)

* Relax dependencies to allow minor releases.

## [Changes in 5.11.0](https://github.com/jaimeiniesta/metainspector/compare/v5.11.0...v5.11.1)

* Upgrade to Nokogiri 1.11.0.

## [Changes in 5.11.0](https://github.com/jaimeiniesta/metainspector/compare/v5.10.1...v5.11.0)

* Upgrade to Faraday 1.1.

## [Changes in 5.10.1](https://github.com/jaimeiniesta/metainspector/compare/v5.10.0...v5.10.1)

* Fix for empty base_href. Makes relative links work when base_href is nil but empty ("").
* Drop support for Ruby 2.4, add support for Ruby 2.7.

## [Changes in 5.10](https://github.com/jaimeiniesta/metainspector/compare/v5.9.0...v5.10.0)

* Upgrade to Faraday 1.0.

## [Changes in 5.9](https://github.com/jaimeiniesta/metainspector/compare/v5.8.0...v5.9.0)

* Added #feeds method to retrieve all feeds of a page.
* Adds deprecation warning on #feed method.

## [Changes in 5.8](https://github.com/jaimeiniesta/metainspector/compare/v5.7.0...v5.8.0)

* Added h1..h6 support.

## [Changes in 5.7](https://github.com/jaimeiniesta/metainspector/compare/v5.6.0...v5.7.0)

* Avoids normalizing image URLs. https://github.com/jaimeiniesta/metainspector/pull/241
* Adds `NonHtmlErrorException` instead of `ParserError` https://github.com/jaimeiniesta/metainspector/pull/248

## [Changes in 5.6](https://github.com/jaimeiniesta/metainspector/compare/v5.5.0...v5.6.0)

* New feature: `:encoding` option for force encoding of a parsed document.
* Improvement: make `best_title` and `best_author` work by order of preference, rather than length.

## [Changes in 5.5](https://github.com/jaimeiniesta/metainspector/compare/v5.4.0...v5.5.0)

* New feature: adds `author`, `best_author`.
* Bugfix: adds presence validation for empty string on meta tag image values.
* Improves spider and links checker examples.
* Uses WebMock instead of FakeWeb in tests.

## [Changes in 5.4](https://github.com/jaimeiniesta/metainspector/compare/v5.3.0...v5.4.0)

* Supports Gzipped responses.
* Adds method `best_description` and makes `description` return just the meta description.
* Removes support for Ruby 2.0.0 and adds support for 2.4.0.

## [Changes in 5.3](https://github.com/jaimeiniesta/metainspector/compare/v5.2.0...v5.3.0)

* Returns secondary description if meta description is empty.
* Adds a custom timeout on top of the ones for Faraday, and sets defaults for timeouts.
* Eliminates possible NULL char in HTML which breaks nokogiri.

## [Changes in 5.2](https://github.com/jaimeiniesta/metainspector/compare/v5.1.0...v5.2.0)

* Removes the deprecated `html_content_only` option, and replaces it by `allow_non_html_content`, by default `false`.

## [Changes in 5.1](https://github.com/jaimeiniesta/metainspector/compare/v5.0.0...v5.1.0)

* Deprecates the `html_content_only` option, and turns it on by default.

## [Changes in 5.0](https://github.com/jaimeiniesta/metainspector/compare/v4.7.1...v5.0.0)

* Removes the ExceptionLog, all exceptions are now encapsulated in our own exception classes and
always raised.

## [Changes in 4.7](https://github.com/jaimeiniesta/metainspector/compare/v4.6.0...v4.7.1)

* MetaInspector can be configured to use [Faraday::HttpCache](https://github.com/plataformatec/faraday-http-cache) to cache page responses. For that you should pass the `faraday_http_cache` option with at least the `:store` key, for example:

```ruby
cache = ActiveSupport::Cache.lookup_store(:file_store, '/tmp/cache')
page = MetaInspector.new('http://example.com', faraday_http_cache: { store: cache })
```

* Bugfixes:
  * Parsing of the document is done as soon as it is initialized (just like we do with the request), so
that parsing errors will be catched earlier.
  * Rescues from Faraday::SSLError.

## [Changes in 4.6](https://github.com/jaimeiniesta/metainspector/compare/v4.5.0...v4.6.0)

* Faraday can be passed options via `:faraday_options`. This is useful in cases where we need to
customize the way we request the page, like for example disabling SSL verification, like this:

```ruby
MetaInspector.new('https://example.com')
# Faraday::SSLError: SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed

MetaInpector.new('https://example.com', faraday_options: { ssl: { verify: false } })
# Now we can access the page
```

## [Changes in 4.5](https://github.com/jaimeiniesta/metainspector/compare/v4.4.0...v4.5.0)

* The Document API now includes access to head/link elements
    * `page.head_links` returns an array of hashes of all head/links.
    * `page.stylesheets` returns head/links where rel='stylesheet'
    * `page.canonicals` returns head/links where rel='canonical'

* The URL API can remove common tracking parameters from the querystring
    * `url.tracked?` will tell you if the url contains known tracking parameters
    * `url.untracked_url` will return the url with known tracking parameters removed
    * `url.untrack!` will remove the tracking parameters from the url

* The images API has been extended:
    * `page.images.with_size` returns a sorted array (by descending area) of [image_url, width, height]

## [Changes in 4.4](https://github.com/jaimeiniesta/metainspector/compare/v4.3.0...v4.4.0)

* The default headers now include `'Accept-Encoding' => 'identity'` to minimize trouble with servers that respond with malformed compressed responses, [as explained here](https://github.com/lostisland/faraday/issues/337).

## [Changes in 4.3](https://github.com/jaimeiniesta/metainspector/compare/v4.3.0...v4.4.0)

* The Document API has been extended with one new method `page.best_title` that returns the longest text available from a selection of candidates.
* `to_hash` now includes `scheme`, `host`, `root_url`, `best_title` and `description`.

## [Changes in 4.2](https://github.com/jaimeiniesta/metainspector/compare/v4.1.0...v4.2.0)

* The images API has been extended, with two new methods:

  * `page.images.owner_suggested` returns the OG or Twitter image, or `nil` if neither are present.
  * `page.images.largest` returns the largest image found in the page. This uses the HTML height and width attributes as well as the [fastimage](https://github.com/sdsykes/fastimage) gem to return the largest image on the page that has a ratio squarer than 1:10 or 10:1. This usually provides a good alternative to the OG or Twitter images if they are not supplied.

* The criteria for `page.images.best` has changed slightly, we'll now return the largest image instead of the first image if no owner-suggested image is found.

## [Changes in 4.1](https://github.com/jaimeiniesta/metainspector/compare/v4.0.0...v4.1.0)

* Introduces the `:normalize_url` option, which allows to disable URL normalization.

## [Changes in 4.0](https://github.com/jaimeiniesta/metainspector/compare/v3.0.0...v4.0.0)

* The links API has been changed, now instead of `page.links`, `page.internal_links` and `page.external_links` we have:

```ruby
page.links.raw      # Returns all links found, unprocessed
page.links.all      # Returns all links found, unrelavitized and absolutified
page.links.http     # Returns all HTTP links found
page.links.non_http # Returns all non-HTTP links found
page.links.internal # Returns all internal HTTP links found
page.links.external # Returns all external HTTP links found
```

* The images API has been changed, now instead of `page.image` we have `page.images.best`, and instead of `page.favicon` we have `page.images.favicon`.

* Now `page.image` will return the first image in `page.images` if no OG or Twitter image found, instead of returning `nil`.

* You can now specify 2 different timeouts, `connection_timeout` and `read_timeout`, instead of the previous single `timeout`.

## [Changes in 3.0](https://github.com/jaimeiniesta/metainspector/compare/v2.0.0...v3.0.0)

* The redirect API has been changed, now the `:allow_redirections` option will expect only a boolean, which by default is `true`. That is, no more specifying `:safe`, `:unsafe` or `:all`.
* We've dropped support for Ruby < 2.

Also, we've introduced a new feature:

* Persist cookies across redirects. Now MetaInspector will include the received cookies when following redirects. This fixes some cases where a redirect would fail, sometimes caught in a redirection loop.
