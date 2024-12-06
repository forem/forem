# MetaInspector
[![Gem Version](https://badge.fury.io/rb/metainspector.svg)](http://badge.fury.io/rb/metainspector) [![CircleCI](https://circleci.com/gh/jaimeiniesta/metainspector.svg?style=svg)](https://circleci.com/gh/jaimeiniesta/metainspector) [![Code Climate](https://codeclimate.com/github/jaimeiniesta/metainspector/badges/gpa.svg)](https://codeclimate.com/github/jaimeiniesta/metainspector) [![Mentioned in Awesome Ruby](https://awesome.re/mentioned-badge.svg)](https://github.com/markets/awesome-ruby)

MetaInspector is a gem for web scraping purposes.

You give it an URL, and it lets you easily get its title, links, images, charset, description, keywords, meta tags...

## Installation

Install the gem from RubyGems:

```bash
gem install metainspector
```

If you're using it on a Rails application, just add it to your Gemfile and run `bundle install`

```ruby
gem 'metainspector'
```

Supported Ruby versions are defined in [`.travis.yml`](.travis.yml).

## Usage

Initialize a MetaInspector instance for an URL, like this:

```ruby
page = MetaInspector.new('http://sitevalidator.com')
```

If you don't include the scheme on the URL, http:// will be used by default:

```ruby
page = MetaInspector.new('sitevalidator.com')
```

You can also include the html which will be used as the document to scrape:

```ruby
page = MetaInspector.new("http://sitevalidator.com",
                         :document => "<html>...</html>")
```

## Accessing response

You can check the status and headers from the response like this:

```ruby
page.response.status  # 200
page.response.headers # { "server"=>"nginx", "content-type"=>"text/html; charset=utf-8",
                      #   "cache-control"=>"must-revalidate, private, max-age=0", ... }
```

## Accessing scraped data

### URL

```ruby
page.url                 # URL of the page
page.tracked?            # returns true if the url contains known tracking parameters
page.untracked_url       # returns the url with the known tracking parameters removed
page.untrack!            # removes the known tracking parameters from the url
page.scheme              # Scheme of the page (http, https)
page.host                # Hostname of the page (like, sitevalidator.com, without the scheme)
page.root_url            # Root url (scheme + host, like http://sitevalidator.com/)
```

### Head links

```ruby
page.head_links          # an array of hashes of all head/links
page.stylesheets         # an array of hashes of all head/links where rel='stylesheet'
page.canonicals          # an array of hashes of all head/links where rel='canonical'
page.feeds               # Get rss or atom links in meta data fields as array of hash in the form { href: "...", title: "...", type: "..." }
```

### Texts

```ruby
page.title               # title of the page from the head section, as string
page.best_title          # best title of the page, from a selection of candidates
page.author              # author of the page from the meta author tag
page.best_author         # best author of the page, from a selection of candidates
page.description         # returns the meta description
page.best_description    # returns the first non-empty description between the following candidates: standard meta description, og:description, twitter:description, the first long paragraph
page.h1                  # returns h1 text array
page.h2                  # returns h2 text array
page.h3                  # returns h3 text array
page.h4                  # returns h4 text array
page.h5                  # returns h5 text array
page.h6                  # returns h6 text array
```

### Links

```ruby
page.links.raw           # every link found, unprocessed
page.links.all           # every link found on the page as an absolute URL
page.links.http          # every HTTP link found
page.links.non_http      # every non-HTTP link found
page.links.internal      # every internal link found on the page as an absolute URL
page.links.external      # every external link found on the page as an absolute URL
```

### Images

```ruby
page.images              # enumerable collection, with every img found on the page as an absolute URL
page.images.with_size    # a sorted array (by descending area) of [image_url, width, height]
page.images.best         # Most relevant image, if defined with the og:image or twitter:image metatags. Fallback to the first page.images array element
page.images.favicon      # absolute URL to the favicon
```

### Meta tags

When it comes to meta tags, you have several options:

```ruby
page.meta_tags  # Gives you all the meta tags by type:
                # (meta name, meta http-equiv, meta property and meta charset)
                # As meta tags can be repeated (in the case of 'og:image', for example),
                # the values returned will be arrays
                #
                # For example:
                #
                # {
                    'name' => {
                                'keywords'       => ['one, two, three'],
                                'description'    => ['the description'],
                                'author'         => ['Joe Sample'],
                                'robots'         => ['index,follow'],
                                'revisit'        => ['15 days'],
                                'dc.date.issued' => ['2011-09-15']
                              },

                    'http-equiv' => {
                                        'content-type'        => ['text/html; charset=UTF-8'],
                                        'content-style-type'  => ['text/css']
                                    },

                    'property' => {
                                    'og:title'        => ['An OG title'],
                                    'og:type'         => ['website'],
                                    'og:url'          => ['http://example.com/meta-tags'],
                                    'og:image'        => ['http://example.com/rock.jpg',
                                                          'http://example.com/rock2.jpg',
                                                          'http://example.com/rock3.jpg'],
                                    'og:image:width'  => ['300'],
                                    'og:image:height' => ['300', '1000']
                                   },

                    'charset' => ['UTF-8']
                  }
```

As this method returns a hash, you can also take only the key that you need, like in:

```ruby
page.meta_tags['property']  # Returns:
                            # {
                            #   'og:title'        => ['An OG title'],
                            #   'og:type'         => ['website'],
                            #   'og:url'          => ['http://example.com/meta-tags'],
                            #   'og:image'        => ['http://example.com/rock.jpg',
                            #                         'http://example.com/rock2.jpg',
                            #                         'http://example.com/rock3.jpg'],
                            #   'og:image:width'  => ['300'],
                            #   'og:image:height' => ['300', '1000']
                            # }
```

In most cases you will only be interested in the first occurrence of a meta tag, so you can
use the singular form of that method:

```ruby
page.meta_tag['name']   # Returns:
                        # {
                        #   'keywords'       => 'one, two, three',
                        #   'description'    => 'the description',
                        #   'author'         => 'Joe Sample',
                        #   'robots'         => 'index,follow',
                        #   'revisit'        => '15 days',
                        #   'dc.date.issued' => '2011-09-15'
                        # }
```

Or, as this is also a hash:

```ruby
page.meta_tag['name']['keywords']    # Returns 'one, two, three'
```

And finally, you can use the shorter `meta` method that will merge the different keys so you have
a simpler hash:

```ruby
page.meta   # Returns:
            #
            # {
            #   'keywords'            => 'one, two, three',
            #   'description'         => 'the description',
            #   'author'              => 'Joe Sample',
            #   'robots'              => 'index,follow',
            #   'revisit'             => '15 days',
            #   'dc.date.issued'      => '2011-09-15',
            #   'content-type'        => 'text/html; charset=UTF-8',
            #   'content-style-type'  => 'text/css',
            #   'og:title'            => 'An OG title',
            #   'og:type'             => 'website',
            #   'og:url'              => 'http://example.com/meta-tags',
            #   'og:image'            => 'http://example.com/rock.jpg',
            #   'og:image:width'      => '300',
            #   'og:image:height'     => '300',
            #   'charset'             => 'UTF-8'
            # }
```

This way, you can get most meta tags just like that:

```ruby
page.meta['author']     # Returns "Joe Sample"
```

Please be aware that all keys are converted to downcase, so it's `'dc.date.issued'` and not `'DC.date.issued'`.

### Misc

```ruby
page.charset             # UTF-8
page.content_type        # content-type returned by the server when the url was requested
```

## Other representations

You can also access most of the scraped data as a hash:

```ruby
page.to_hash    # { "url"   => "http://sitevalidator.com",
                    "title" => "MarkupValidator :: site-wide markup validation tool", ... }
```

The original document is accessible from:

```ruby
page.to_s         # A String with the contents of the HTML document
```

And the full scraped document is accessible from:

```ruby
page.parsed  # Nokogiri doc that you can use it to get any element from the page
```

## Options

### Forced encoding

If you get a `MetaInspector::RequestError, "invalid byte sequence in UTF-8"` or similar error, you can try forcing the encoding like this:

```ruby
page = MetaInspector.new(url, :encoding => 'UTF-8')
```

### Timeout & Retries

You can specify 2 different timeouts when requesting a page:

* `connection_timeout` sets the maximum number of seconds to wait to get a connection to the page.
* `read_timeout` sets the maximum number of seconds to wait to read the page, once connected.

Both timeouts default to 20 seconds each.

You can also specify the number of `retries`, which defaults to 3.

For example, this will time out after 10 seconds waiting for a connection, or after 5 seconds waiting
to read its contents, and will retry 4 times:

```ruby
page = MetaInspector.new('www.google', :connection_timeout => 10, :read_timeout => 5, :retries => 4)
```

If MetaInspector fails to fetch the page after it has exhausted its retries,
it will raise `MetaInspector::TimeoutError`, which you can rescue in your
application code.

```ruby
begin
  page = MetaInspector.new(url)
rescue MetaInspector::TimeoutError
  enqueue_for_future_fetch_attempt(url)
  render_simple(url)
else
  render_rich(page)
end
```

### Redirections

By default, MetaInspector will follow redirects (up to a limit of 10).

If you want to disallow redirects, you can do it like this:

```ruby
page = MetaInspector.new('facebook.com', :allow_redirections => false)
```

You can also customize how many redirects you wish to allow:

```ruby
page = MetaInspector.new('facebook.com', :faraday_options => { redirect: { limit: 5 } })
```

And even customize what to do in between each redirect:

```ruby
callback = proc do |previous_response, next_request|
  ip_address = Resolv.getaddress(next_request.url.host)
  raise 'Invalid address' if IPAddr.new(ip_address).private?
end

page = MetaInspector.new(url, faraday_options: { redirect: { callback: callback } })
```


The `faraday_options[:redirect]` hash is passed to the `FollowRedirects` middleware used by `Faraday`, so that we can use all available options.
Check them [here](https://github.com/lostisland/faraday_middleware/blob/main/lib/faraday_middleware/response/follow_redirects.rb#L44).

### Headers

By default, the following headers are set:

```ruby
{
  'User-Agent'      => "MetaInspector/#{MetaInspector::VERSION} (+https://github.com/jaimeiniesta/metainspector)",
  'Accept-Encoding' => 'identity'
}
```

The `Accept-Encoding` is set to `identity` to avoid exceptions being raised on servers that return malformed compressed responses, [as explained here](https://github.com/lostisland/faraday/issues/337).

If you want to override the default headers then use the `headers` option:

```ruby
# Set the User-Agent header
page = MetaInspector.new('example.com', :headers => {'User-Agent' => 'My custom User-Agent'})
```

### Disabling SSL verification (or any other Faraday options)

Faraday can be passed options via `:faraday_options`.

This is useful in cases where we need to
customize the way we request the page, like for example disabling SSL verification, like this:

```ruby
MetaInspector.new('https://example.com')
# Faraday::SSLError: SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed

MetaInspector.new('https://example.com', faraday_options: { ssl: { verify: false } })
# Now we can access the page
```

### Allow non-HTML content type

MetaInspector will by default raise an exception when trying to parse a non-HTML URL (one that has a content-type different than text/html). You can disable this behaviour with:

```ruby
page = MetaInspector.new('sitevalidator.com', :allow_non_html_content => true)
```

```ruby
page = MetaInspector.new('http://example.com/image.png')
page.content_type  # "image/png"
page.description   # will raise an exception

page = MetaInspector.new('http://example.com/image.png', :allow_non_html_content => true)
page.content_type  # "image/png"
page.description   # will return a garbled string
```

### URL Normalization

By default, URLs are normalized using the Addressable gem. For example:

```ruby
# Normalization will add a default scheme and a trailing slash...
page = MetaInspector.new('sitevalidator.com')
page.url # http://sitevalidator.com/

# ...and it will also convert international characters
page = MetaInspector.new('http://www.詹姆斯.com')
page.url # http://www.xn--8ws00zhy3a.com/
```

While this is generally useful, it can be [tricky](https://github.com/sporkmonger/addressable/issues/182) [sometimes](https://github.com/sporkmonger/addressable/issues/160).

You can disable URL normalization by passing the `normalize_url: false` option.

### Image downloading

When you ask for the largest image on the page with `page.images.largest`, it will be determined by its height and width attributes on the HTML markup, and also by downloading a small portion of each image using the [fastimage](https://github.com/sdsykes/fastimage) gem. This is really fast as it doesn't download the entire images, normally just the headers of the image files.

If you want to disable this, you can specify it like this:

```ruby
page = MetaInspector.new('http://example.com', download_images: false)
```

### Caching responses

MetaInspector can be configured to use [Faraday::HttpCache](https://github.com/plataformatec/faraday-http-cache) to cache page responses. For that you should pass the `faraday_http_cache` option with at least the `:store` key, for example:

```ruby
cache = ActiveSupport::Cache.lookup_store(:file_store, '/tmp/cache')
page = MetaInspector.new('http://example.com', faraday_http_cache: { store: cache })
```

## Exception Handling

Web page scraping is tricky, you can expect to find different exceptions during the request of the page or the parsing of its contents. MetaInspector will encapsulate these exceptions on these main errors:

* `MetaInspector::TimeoutError`. When fetching a web page has taken too long.
* `MetaInspector::RequestError`. When there has been an error on the request phase. Examples: page not found, SSL failure, invalid URI.
* `MetaInspector::ParserError`. When there has been an error parsing the contents of the page.
* `MetaInspector::NonHtmlError`. When the contents of the page was not HTML. See also the `allow_non_html_content` option

## Examples

You can find some sample scripts on the `examples` folder, including a basic scraping and a spider that will follow external links using a queue. What follows is an example of use from irb:

```ruby
$ irb
>> require 'metainspector'
=> true

>> page = MetaInspector.new('http://sitevalidator.com')
=> #<MetaInspector:0x11330c0 @url="http://sitevalidator.com">

>> page.title
=> "MarkupValidator :: site-wide markup validation tool"

>> page.meta['description']
=> "Site-wide markup validation tool. Validate the markup of your whole site with just one click."

>> page.meta['keywords']
=> "html, markup, validation, validator, tool, w3c, development, standards, free"

>> page.links.size
=> 15

>> page.links[4]
=> "/plans-and-pricing"
```

## Contributing guidelines

You're more than welcome to fork this project and send pull requests. Just remember to:

* Create a topic branch for your changes.
* Add specs.
* Keep your fake responses as small as possible. For each change in `spec/fixtures`, a comment should be included explaining why it's needed.
* Update `README.md` if needed (for example, when you're adding or changing a feature).

Thanks to all the contributors:

[https://github.com/jaimeiniesta/metainspector/graphs/contributors](https://github.com/jaimeiniesta/metainspector/graphs/contributors)

You can also come to chat with us on our [Gitter room](https://gitter.im/jaimeiniesta/metainspector) and [Google group](https://groups.google.com/forum/#!forum/metainspector).

## Related projects

* [go-metainspector](https://github.com/fern4lvarez/go-metainspector), a port of MetaInspector for Go.
* [Node-MetaInspector](https://github.com/gabceb/node-metainspector), a port of MetaInspector for Node.
* [MetaInvestigator](https://github.com/nekova/metainvestigator), a port of MetaInspector for Elixir.
* [Funkspector](https://github.com/jaimeiniesta/funkspector), another port of MetaInspector for Elixir.

## License
MetaInspector is released under the [MIT license](MIT-LICENSE).
