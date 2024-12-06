# CarrierWave::BombShelter

[![Build Status](https://travis-ci.org/DarthSim/carrierwave-bombshelter.svg)](https://travis-ci.org/DarthSim/carrierwave-bombshelter)

BombShelter is a module which protects your uploaders from image bombs like https://www.bamsoftware.com/hacks/deflate.html and http://www.openwall.com/lists/oss-security/2016/05/03/18. It checks type and pixel dimensions of uploaded image before ImageMagick touches it.

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54">
</a>

## How it works

BombShelter uses [fastimage](https://github.com/sdsykes/fastimage) gem, which reads just a header of an image to get info about it. BombShelter compares type and pixel dimensions of the uploaded image with allowed ones and raises integrity error if image is too big or have unsupported type. Works perfectly with ActiveRecord validators.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'carrierwave-bombshelter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install carrierwave-bombshelter

## Usage

Just include `CarrierWave::BombShelter` to your uploader and you're done:

```ruby
class YourUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter
end
```

You can change allowed image types by defining `image_type_whitelist` method (default are `[:jpeg, :png, :gif]`):

```ruby
class YourUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter

  def image_type_whitelist
    [:bmp, :jpeg, :png, :gif]
  end
end
```

**Note:** Whitelisted file types should be supported by [fastimage](https://github.com/sdsykes/fastimage).

**Warning:** Allowing `svg` and `mvg` is totally insecure.

You can change maximum allowed dimensions by defining `max_pixel_dimensions` method (default is 4096x4096):

```ruby
class YourUploader < CarrierWave::Uploader::Base
  include CarrierWave::BombShelter

  def max_pixel_dimensions
    [1024, 1024]
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/DarthSim/carrierwave-bombshelter. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org/) code of conduct.

#### Locales

Please don't create PRs that add locales. I can't maintain locales of languages that I don't know, and I can't poke you every time when I need to add a new string.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
