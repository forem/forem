# Fastly [![Build Status](https://travis-ci.org/fastly/fastly-ruby.svg?branch=master)](https://travis-ci.org/fastly/fastly-ruby)

Client library for interacting with the Fastly web acceleration service [API](http://docs.fastly.com/api)

### A Note About Authentication

Authenticating with a username/password is deprecated and will no longer be available starting September 2020.

Authenticating with an API Token is shown in the example section below. For more information on API Tokens, please see [Fastly's API Token documentation](https://developer.fastly.com/reference/api/auth/). For more information about authenticating to our API, please see our [Authentication section](https://developer.fastly.com/reference/api/#authentication).

## Examples

Add fastly to your Gemfile:
```ruby
gem 'fastly'
```

Create a fastly client:

```ruby
# some_file.rb
# username/password authentication is deprecated and will not be available
# starting September 2020; use {api_key: 'your-key'} as the login option
fastly = Fastly.new(login_opts)

current_user     = fastly.current_user
current_customer = fastly.current_customer

user     = fastly.get_user(current_user.id)
customer = fastly.get_customer(current_customer.id)

puts "Name: #{user.name}"
puts "Works for #{user.customer.name}"
puts "Which is the same as #{customer.name}"
puts "Which has the owner #{customer.owner.name}"
```

List the services we have defined:

```ruby
fastly.list_services.each do |service|
  puts "Service ID: #{service.id}"
  puts "Service Name: #{service.name}"
  puts "Service Versions:"
  service.versions.each do |version|
    puts "\t#{version.number}"
  end
end

service        = fastly.create_service(name: "MyFirstService")
latest_version = service.version
```

Create a domain and a backend for the service:

```ruby
domain =
  fastly.create_domain(service_id: service.id,
                       version: latest_version.number,
                       name: "www.example.com")

backend =
  fastly.create_backend(service_id: service.id,
                        version: latest_version.number,
                        name: "Backend 1",
                        ipv4: "192.0.43.10",
                        port: 80)
```

Activate the service:

```ruby
latest_version.activate!
```

You're now hosted on Fastly.

Let's look at the VCL that Fastly generated for us:

```ruby
vcl = latest_version.generated_vcl

puts "Generated VCL file is:"
puts vcl.content
```

Now let's create a new version:

```ruby
new_version = latest_version.clone
```

Add a new backend:

```ruby
new_backend =
  fastly.create_backend(service_id: service.id,
                        version: new_version.number,
                        name: "Backend 2",
                        ipv4: "74.125.224.136",
                        port: 8080)
```

Add a director to switch between them:

```ruby
director =
  fastly.create_director(service_id: service.id,
                         version: new_version.number,
                         name: "My Director")

director.add_backend(backend)
director.add_backend(new_backend)
```

Upload some custom VCL (presuming we have permissions):

```ruby
custom_vcl = File.read(vcl_file)

new_version.upload_vcl(vcl_name, custom_vcl)
```

Set the custom VCL as the service's main VCL

```ruby
new_version.vcl(vcl_name).set_main!

new_version.activate!
```

### Efficient purging

Purging requires your Fastly credentials and the service you want to purge
content from.  To purge efficiently you do not want to look up the service
every time you issue a purge:

```ruby
fastly  = Fastly.new(api_key: 'YOUR_API_KEY')
service = Fastly::Service.new({ id: 'YOUR_SERVICE_ID' }, fastly)

# purge an individual url
fastly.purge(url)

# purge everything:
service.purge_all

# purge by key:
service.purge_by_key('YOUR_SURROGATE_KEY')

# 'soft' purging
# see https://docs.fastly.com/guides/purging/soft-purges
fastly.purge(url, true)
service.purge_by_key('YOUR_SURROGATE_KEY', true)
```

You can also purge without involving the Fastly client by sending a PURGE request directly
to the URL you want to purge. You can also send a POST request to the API with your Fastly API key
in a `Fastly-Key` header:

```
curl -X PURGE YOUR URL

curl -H 'Fastly-Key: YOUR_API_KEY' -X POST \
  https://api.fastly.com/service/YOUR_SERVICE_ID/purge/YOUR_SURROGATE_KEY
```

Previously purging made an POST call to the `/purge` endpoint of the Fastly API.

The new method of purging is done by making an HTTP request against the URL using the `PURGE` HTTP method.

This gem now uses the new method. The old method can be used by passing the `use_old_purge_method` option into the constructor.

```ruby
fastly = Fastly.new(login_opts.merge(use_old_purge_method: true))
fastly.purge(url, true)
service.purge_by_key('YOUR_SURROGATE_KEY', true)
```

See the [Fastly purging API documentation](https://docs.fastly.com/api/purge)
for more information and examples.

## Usage notes

If you are performing many purges per second we recommend you use the API
directly with an HTTP client of your choice.  See Efficient Purging above.

fastly-ruby has not been audited for thread-safety.  If you are performing
actions that require multiple threads (such as performing many purges) we
recommend you use the API directly.

### Debugging notes

You can pass a `:debug` argument to the initializer. This will output verbose HTTP logs for all API interactions. For example, the following will print logs to STDERR:

```
client = Fastly.new(debug: STDERR, api_key: 'YOUR_API_KEY')
```

This option should not be used in a production setting as all HTTP headers, request parameters, and bodies will be logged, which may include sensitive information.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Notes for testing

The test suite tests create and delete three services in sequence, so you may want to create an account just for these tests.

To run the test suite:

1. Generate a personal token for these tests: https://manage.fastly.com/account/personal/tokens

2. Copy `.env.example` to `.env` and add the values for the variables:

  * `FASTLY_TEST_USER` - Your user email
  * `FASTLY_TEST_PASSWORD` - Your account password
  * `FASTLY_TEST_API_KEY` - Your personal token

3. Run the tests via `bundle exec rake test:unit`

## Copyright

Copyright 2011-2020 - Fastly, Inc.

## Redistribution

MIT license, see [LICENSE](LICENSE).

## Contact

Mail support at fastly dot com if you have problems.

## Developers

* http://github.com/fastly/fastly-ruby
* https://docs.fastly.com/api/
