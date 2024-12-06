# aws_cf_signer

Small gem for signing AWS CloudFront URLs given a AWS key_pair_id and pem file. Read more here:
http://docs.amazonwebservices.com/AmazonCloudFront/latest/DeveloperGuide/index.html?PrivateContent.html

## Installation

In your Gemfile.

    gem 'aws_cf_signer'

Or on your system.

    gem install aws_cf_signer

## Usage

```ruby
# Pass in path to the private CloudFront key from AWS
signer = AwsCfSigner.new('/path/to/my/pk-1234567890.pem')

# If the key filename doesn't contain the key_pair_id (as it usually does from AWS), pass that in as the second arg
signer = AwsCfSigner.new('/path/to/my/private-key.pem', '1234567890')

# If your private key is not on the filesystem, you can pass it explicitly, you need to pass key_pair_id if you do that
signer = AwsCfSigner.new(ENV["CLOUDFLARE_PRIVATE_KEY"], '1234567890')

# expiration date is required
# See Example Canned Policy at above AWS doc link
url = signer.sign('http://d604721fxaaqy9.cloudfront.net/horizon.jpg?large=yes&license=yes', :ending => 'Sat, 14 Nov 2009 22:20:00 GMT')

# You can also use a Time object
url = signer.sign('http://d604721fxaaqy9.cloudfront.net/horizon.jpg?large=yes&license=yes', :ending => Time.now + 3600)

# Custom Policies

# See Example Custom Policy 1 at above AWS doc link
url = signer.sign('http://d604721fxaaqy9.cloudfront.net/training/orientation.avi',
  :ending   => 'Sat, 14 Nov 2009 22:20:00 GMT',
  :resource => 'http://d604721fxaaqy9.cloudfront.net/training/*',
  :ip_range => '145.168.143.0/24'
)

# See Example Custom Policy 2 at above AWS doc link
url = signer.sign('http://d84l721fxaaqy9.cloudfront.net/downloads/pictures.tgz',
  :starting => 'Thu, 30 Apr 2009 06:43:10 GMT',
  :ending   => 'Fri, 16 Oct 2009 06:31:56 GMT',
  :resource => 'http://*',
  :ip_range => '216.98.35.1/32'
)

# You can also pass in a path to a policy file
# This will supersede any other policy options
url = signer.sign('http://d84l721fxaaqy9.cloudfront.net/downloads/pictures.tgz',
  :policy_file => '/path/to/policy/file.txt'
)
```

See the test/test_aws_cf_signer.rb file for more examples.

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Attributions

Parts of signing code taken from a question on Stack Overflow asked by Ben Wiseley, and answered by Blaz Lipuscek and Manual M:

* http://stackoverflow.com/questions/2632457/create-signed-urls-for-cloudfront-with-ruby
* http://stackoverflow.com/users/315829/ben-wiseley
* http://stackoverflow.com/users/267804/blaz-lipuscek
* http://stackoverflow.com/users/327914/manuel-m

## License

aws_cf_signer is distributed under the MIT License, copyright © 2010 STL, Dylan Vaughn
