# Fog::Aws

![Gem Version](https://badge.fury.io/rb/fog-aws.svg)
[![Build Status](https://github.com/fog/fog-aws/actions/workflows/ruby.yml/badge.svg)](https://github.com/fog/fog-aws/actions/workflows/ruby.yml)
[![Test Coverage](https://codeclimate.com/github/fog/fog-aws/badges/coverage.svg)](https://codeclimate.com/github/fog/fog-aws)
[![Code Climate](https://codeclimate.com/github/fog/fog-aws.svg)](https://codeclimate.com/github/fog/fog-aws)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fog-aws'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fog-aws

## Usage

Before you can use fog-aws, you must require it in your application:

```ruby
require 'fog/aws'
```

Since it's a bad practice to have your credentials in source code, you should load them from default fog configuration file: ```~/.fog```. This file could look like this:

```
default:
  aws_access_key_id:     <YOUR_ACCESS_KEY_ID>
  aws_secret_access_key: <YOUR_SECRET_ACCESS_KEY>
```

### EC2

#### Connecting to the EC2 Service:

```ruby
ec2 = Fog::Compute.new :provider => 'AWS', :region => 'us-west-2'
```

You can review all the requests available with this service using ```#requests``` method:

```ruby
ec2.requests # => [:allocate_address, :assign_private_ip_addresses, :associate_address, ...]
```

#### Launch an EC2 on-demand instance:

```ruby
response = ec2.run_instances(
  "ami-23ebb513",
  1,
  1,
  "InstanceType"  => "t1.micro",
  "SecurityGroup" => "ssh",
  "KeyName"       => "miguel"
)
instance_id = response.body["instancesSet"].first["instanceId"] # => "i-02db5af4"
instance = ec2.servers.get(instance_id)
instance.wait_for { ready? }
puts instance.public_ip_address # => "356.300.501.20"
```

#### Terminate an EC2 instance:

```ruby
instance = ec2.servers.get("i-02db5af4")
instance.destroy
```

`Fog::AWS` is more than EC2 since it supports many services provided by AWS. The best way to learn and to know about how many services are supported is to take a look at the source code. To review the tests directory and to play with the library in ```bin/console``` can be very helpful resources as well.

### S3

#### Connecting to the S3 Service:

```ruby
s3 = Fog::Storage.new(provider: 'AWS', region: 'eu-central-1')
```

#### Creating a file:

```ruby
directory = s3.directories.new(key: 'gaudi-portal-dev')
file = directory.files.create(key: 'user/1/Gemfile', body: File.open('Gemfile'), tags: 'Org-Id=1&Service-Name=My-Service')
```

#### Listing files:

```ruby
directory = s3.directories.get('gaudi-portal-dev', prefix: 'user/1/')
directory.files
```
**Warning!** `s3.directories.get` retrieves and caches meta data for the first 10,000 objects in the bucket, which can be very expensive. When possible use `s3.directories.new`.

#### Generating a URL for a file:

```ruby
directory.files.new(key: 'user/1/Gemfile').url(Time.now + 60)
```

##### Generate download URL
You should pass an option argument that contains the `query` key with `response-content-disposition` inside indicating that is an attachment and the filename to be used when downloaded.

```ruby
options = {
  query: {
    'response-content-disposition' => "attachment; filename=#{key}"
  }
}

directory.files.new(key: 'user/1/Gemfile').url(Time.now + 60, options)
```


##### Controlling credential refresh time with IAM authentication

When using IAM authentication with
[temporary security credentials](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html),
generated S3 pre-signed URLs
[only last as long as the temporary credential](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ShareObjectPreSignedURL.html).

Generating the URLs in the following manner will return a URL
that will not last as long as its requested expiration time if
the remainder of the authentication token lifetime was shorter.

```ruby
s3 = Fog::Storage.new(provider: 'AWS', use_iam_profile: true)
directory = s3.directories.get('gaudi-portal-dev', prefix: 'user/1/')

directory.files.new(key: 'user/1/Gemfile').url(Time.now + 60)
```

By default the temporary credentials in use are refreshed only within the last
15 seconds of its expiration time. The URL requested with 60 seconds lifetime
using the above example will only remain valid for 15 seconds in the worst case.

The problem can be avoided by refreshing the token early and often,
by setting configuration `aws_credentials_refresh_threshold_seconds` (default: 15)
which controls the time when the refresh must occur. It is expressed in seconds
before the temporary credential's expiration time.

The following example can ensure pre-signed URLs last as long as 60 seconds
by automatically refreshing the credentials when its remainder lifetime
is lower than 60 seconds:

```ruby
s3 = Fog::Storage.new(
  provider: 'AWS',
  use_iam_profile: true,
  aws_credentials_refresh_threshold_seconds: 60
)
directory = s3.directories.get('gaudi-portal-dev', prefix: 'user/1/')

directory.files.new(key: 'user/1/Gemfile').url(Time.now + 60)
```

#### Copying a file

```ruby
directory = s3.directories.new(key: 'gaudi-portal-dev')
file = directory.files.get('user/1/Gemfile')
file.copy("target-bucket", "user/2/Gemfile.copy")
```

To speed transfers of large files, the `concurrency` option can be used
to spawn multiple threads. Note that the file must be at least 5 MB for
multipart uploads to work. For example:

```ruby
directory = s3.directories.new(key: 'gaudi-portal-dev')
file = directory.files.get('user/1/Gemfile')
file.multipart_chunk_size = 10 * 1024 * 1024
file.concurrency = 10
file.copy("target-bucket", "user/2/Gemfile.copy")
```

## Documentation

See the [online documentation](http://www.rubydoc.info/github/fog/fog-aws) for a complete API reference.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

1. Fork it ( https://github.com/fog/fog-aws/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
