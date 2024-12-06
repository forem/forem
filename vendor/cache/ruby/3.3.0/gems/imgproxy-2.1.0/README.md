# imgproxy.rb

<img align="right" width="200" height="200" title="imgproxy logo"
     src="https://cdn.rawgit.com/DarthSim/imgproxy/master/logo.svg">

[![GH Test](https://img.shields.io/github/workflow/status/imgproxy/imgproxy.rb/Test?label=Test&logo=github&style=for-the-badge)](https://github.com/imgproxy/imgproxy.rb/actions) [![GH Lint](https://img.shields.io/github/workflow/status/imgproxy/imgproxy.rb/Lint?label=Lint&logo=github&style=for-the-badge)](https://github.com/imgproxy/imgproxy.rb/actions) [![Gem](https://img.shields.io/gem/v/imgproxy.svg?style=for-the-badge)](https://rubygems.org/gems/imgproxy) [![rubydoc.org](https://img.shields.io/badge/rubydoc-reference-blue.svg?style=for-the-badge)](https://www.rubydoc.info/gems/imgproxy)

**[imgproxy](https://github.com/imgproxy/imgproxy)** is a fast and secure standalone server for resizing and converting remote images. The main principles of imgproxy are simplicity, speed, and security. It is a Go application, ready to be installed and used in any Unix environment—also ready to be containerized using Docker.

imgproxy can be used to provide a fast and secure way to _get rid of all the image resizing code_ in your web application (like calling ImageMagick or GraphicsMagick, or using libraries), while also being able to resize everything on the fly on a separate server that only you control. imgproxy is fast, easy to use, and requires zero processing power or storage from the main application. imgproxy is indispensable when handling image resizing of epic proportions, especially when original images are coming from a remote source.

[imgproxy.rb](https://github.com/imgproxy/imgproxy.rb) is a framework-agnostic Ruby Gem for imgproxy that includes proper support for Ruby on Rails' most popular image attachment options: [Active Storage](https://edgeguides.rubyonrails.org/active_storage_overview.html) and [Shrine](https://github.com/shrinerb/shrine).

**NOTE:** this readme shows documentation for 2.x version. For version 1.x see the [v1.2.0](https://github.com/imgproxy/imgproxy.rb/tree/v1.2.0) tag. See [2.0-Upgrade.md](2.0-Upgrade.md) for the upgrade guide.

<a href="https://evilmartians.com/?utm_source=imgproxy.rb">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54">
</a>

## Installation

Add this to your `Gemfile`:

```ruby
gem "imgproxy"
```

or install system-wide:

```
gem install imgproxy
```

## Configuration

imgproxy.rb uses [anyway_config](https://github.com/palkan/anyway_config) to load configuration, so you can configure it in different ways.

- With a separate config file:

```yaml
# <Rails root>/config/imgproxy.yml
development:
  # Full URL to where your imgproxy lives.
  endpoint: "http://imgproxy.example.com"
  # Hex-encoded signature key and salt
  key: "your_key"
  salt: "your_salt"
production: ...
test: ...
```

- With a `secrets.yml` entry for imgproxy:

```yaml
# secrets.yml
production:
  ...
  imgproxy:
    # Full URL to where your imgproxy lives.
    endpoint: "http://imgproxy.example.com"
    # Hex-encoded signature key and salt
    key: "your_key"
    salt: "your_salt"
...
```

- With environment variables:

```bash
IMGPROXY_ENDPOINT="http://imgproxy.example.com"\
IMGPROXY_KEY="your_key"\
IMGPROXY_SALT="your_salt"\
rails s
```

- ...or right in your application code:

```ruby
# config/initializers/imgproxy.rb

Imgproxy.configure do |config|
  # Full URL to where your imgproxy lives.
  config.endpoint = "http://imgproxy.example.com"
  # Hex-encoded signature key and salt
  config.key = "your_key"
  config.salt = "your_salt"
end
```

#### Configuration options

- **endpoint** (`IMGPROXY_ENDPOINT`) - Full URL to your imgproxy instance. Default: `nil`.
- **key** (`IMGPROXY_KEY`) - Hex-encoded signature key. Default: `nil`.
- **salt** (`IMGPROXY_SALT`) - Hex-encoded signature salt. Default: `nil`.
- **raw_key** (`IMGPROXY_RAW_KEY`) - Raw (not hex-encoded) signature key. Default: `nil`.
- **raw_salt** (`IMGPROXY_RAW_SALT`) - Raw (not hex-encoded) signature salt. Default: `nil`.
- **signature_size** (`IMGPROXY_SIGNATURE_SIZE`) - Signature size. See [URL signature](https://docs.imgproxy.net/#/configuration?id=url-signature) section of imgproxy docs. Default: 32.
- **use_short_options** (`IMGPROXY_USE_SHORT_OPTIONS`) - Use short processing options names (`rs` for `resize`, `g` for `gravity`, etc). Default: true.
- **base64_encode_urls** (`IMGPROXY_BASE64_ENCODE_URLS`) - Encode source URLs to base64. Default: false.
- **always_escape_plain_urls** (`IMGPROXY_ALWAYS_ESCAPE_PLAIN_URLS`) - Always escape plain source URLs even when ones don't need to be escaped. Default: false.
- **use_s3_urls** (`IMGPROXY_USE_S3_URLS`) - Use `s3://...` source URLs for Active Storage and Shrine attachments stored in Amazon S3. Default: false.
- **use_gcs_urls** (`IMGPROXY_USE_GCS_URLS`) - Use `gs://...` source URLs for Active Storage and Shrine attachments stored in Google Cloud Storage. Default: false.
- **gcs_bucket** (`IMGPROXY_GCS_BUCKET`) - Google Cloud Storage bucket name. Default: `nil`.
- **shrine_host** (`IMGPROXY_SHRINE_HOST`) - Shrine host for locally stored files.

## Usage

### Using with Active Storage

imgproxy.rb comes with the Active Storage support built-in. It is enabled _automagically_ if you load `imgproxy` gem after `rails` (basically, just put `gem "imgproxy"` after `gem "rails"` in your `Gemfile`). Otherwise, modify your initializer at `config/initializers/imgproxy.rb`:

```ruby
# config/initializers/imgproxy.rb

Imgproxy.extend_active_storage!
```

Now, to add imgproxy processing to your image attachments, just use the `imgproxy_url` method:

```ruby
user.avatar.imgproxy_url(width: 250, height: 250)
```

This method will return an URL to your user's avatar, resized to 250x250px on the fly.

#### Amazon S3

If you have configured both your imgproxy server and Active Storage to work with Amazon S3, you can use `use_s3_urls` config option (or `IMGPROXY_USE_S3_URLS` env variable) to make imgproxy.rb use short `s3://...` source URLs instead of long ones generated by Rails.

#### Google Cloud Storage

You can also enable `gs://...` URLs usage for the files stored in Google Cloud Storage with `use_gcs_urls` and `gcs_bucket` config options (or `IMGPROXY_USE_GCS_URLS` and `IMGPROXY_GCS_BUCKET` env variables).

**NOTE** that you need to explicitly provide GCS bucket name since Active Storage "hides" the GCS config.

### Using with Shrine

You can also use imgproxy.rb's built-in [Shrine](https://github.com/shrinerb/shrine) support. It is enabled automagically if you load `imgproxy` gem after `shrine` (basically, just put `gem "imgproxy"` after `gem "shrine"` in your `Gemfile`). Otherwise, modify your initializer at `config/initializers/imgproxy.rb`:

```ruby
# config/initializers/imgproxy.rb

Imgproxy.extend_shrine!
```

Now you can use `imgproxy_url` method of `Shrine::UploadedFile`:

```ruby
user.avatar.imgproxy_url(width: 250, height: 250)
```

This method will return an URL to your user's avatar, resized to 250x250px on the fly.

**NOTE:** If you use `Shrine::Storage::FileSystem` as storage, uploaded file URLs won't include the hostname, so imgproxy server won't be able to access them. To fix this, use `shrine_host` config.

Alternatively, you can launch your imgproxy server with the `IMGPROXY_BASE_URL` setting:

```
IMGPROXY_BASE_URL="http://your-host.test" imgproxy
```

#### Amazon S3

If you have configured both your imgproxy server and Shrine to work with Amazon S3, you can use `use_s3_urls` config option (or `IMGPROXY_USE_S3_URLS` env variable) to make imgproxy.rb use short `s3://...` source URLs instead of long ones generated by Shrine.

### Usage imgproxy.rb in a framework-agnostic way

If you use another gem for your attachment operations, you like to keep things minimal or Rails-free, or if you want to generate imgproxy URLs for pictures that did not originate from your application, you can use the `Imgproxy.url_for` method:

```ruby
Imgproxy.url_for(
  "http://images.example.com/images/image.jpg",
  width: 500,
  height: 400,
  resizing_type: :fill,
  sharpen: 0.5
)
# => http://imgproxy.example.com/2tjGMpWqjO/rs:fill:500:400/sh:0.5/plain/http://images.example.com/images/image.jpg
```

You can reuse processing options by using `Imgproxy::Builder`:

```ruby
builder = Imgproxy::Builder.new(
  width: 500,
  height: 400,
  resizing_type: :fill,
  sharpen: 0.5
)

builder.url_for("http://images.example.com/images/image1.jpg")
builder.url_for("http://images.example.com/images/image2.jpg")
```

### Supported imgproxy processing options

- [resize](https://docs.imgproxy.net/#/generating_the_url_advanced?id=resize)
- [size](https://docs.imgproxy.net/#/generating_the_url_advanced?id=size)
- [resizing_type](https://docs.imgproxy.net/#/generating_the_url_advanced?id=resizing-type)
- [resizing_algorithm](https://docs.imgproxy.net/#/generating_the_url_advanced?id=resizing-algorithm) _(pro)_
- [width](https://docs.imgproxy.net/#/generating_the_url_advanced?id=width)
- [height](https://docs.imgproxy.net/#/generating_the_url_advanced?id=height)
- [dpr](https://docs.imgproxy.net/#/generating_the_url_advanced?id=dpr)
- [enlarge](https://docs.imgproxy.net/#/generating_the_url_advanced?id=enlarge)
- [extend](https://docs.imgproxy.net/#/generating_the_url_advanced?id=extend)
- [gravity](https://docs.imgproxy.net/#/generating_the_url_advanced?id=gravity)
- [crop](https://docs.imgproxy.net/#/generating_the_url_advanced?id=crop)
- [padding](https://docs.imgproxy.net/#/generating_the_url_advanced?id=padding)
- [trim](https://docs.imgproxy.net/#/generating_the_url_advanced?id=trim)
- [rotate](https://docs.imgproxy.net/#/generating_the_url_advanced?id=rotate)
- [quality](https://docs.imgproxy.net/#/generating_the_url_advanced?id=quality)
- [max_bytes](https://docs.imgproxy.net/#/generating_the_url_advanced?id=max-bytes)
- [background](https://docs.imgproxy.net/#/generating_the_url_advanced?id=background)
- [background_alpha](https://docs.imgproxy.net/#/generating_the_url_advanced?id=background-alpha) _(pro)_
- [adjust](https://docs.imgproxy.net/#/generating_the_url_advanced?id=adjust) _(pro)_
- [brightness](https://docs.imgproxy.net/#/generating_the_url_advanced?id=brightness) _(pro)_
- [contrast](https://docs.imgproxy.net/#/generating_the_url_advanced?id=contrast) _(pro)_
- [saturation](https://docs.imgproxy.net/#/generating_the_url_advanced?id=saturation) _(pro)_
- [blur](https://docs.imgproxy.net/#/generating_the_url_advanced?id=blur)
- [sharpen](https://docs.imgproxy.net/#/generating_the_url_advanced?id=sharpen)
- [pixelate](https://docs.imgproxy.net/#/generating_the_url_advanced?id=pixelate) _(pro)_
- [unsharpening](https://docs.imgproxy.net/#/generating_the_url_advanced?id=unsharpening) _(pro)_
- [watermark](https://docs.imgproxy.net/#/generating_the_url_advanced?id=watermark)
- [watermark_url](https://docs.imgproxy.net/#/generating_the_url_advanced?id=watermark-url) _(pro)_
- [style](https://docs.imgproxy.net/#/generating_the_url_advanced?id=style) _(pro)_
- [jpeg_options](https://docs.imgproxy.net/#/generating_the_url_advanced?id=jpeg-options) _(pro)_
- [png_options](https://docs.imgproxy.net/#/generating_the_url_advanced?id=png-options) _(pro)_
- [gif_options](https://docs.imgproxy.net/#/generating_the_url_advanced?id=gif-options) _(pro)_
- [page](https://docs.imgproxy.net/#/generating_the_url_advanced?id=page) _(pro)_
- [video_thumbnail_second](https://docs.imgproxy.net/#/generating_the_url_advanced?id=video-thumbnail-second) _(pro)_
- [preset](https://docs.imgproxy.net/#/generating_the_url_advanced?id=preset)
- [cachebuster](https://docs.imgproxy.net/#/generating_the_url_advanced?id=cachebuster)
- [strip_metadata](https://docs.imgproxy.net/#/generating_the_url_advanced?id=strip-metadata)
- [strip_color_profile](https://docs.imgproxy.net/#/generating_the_url_advanced?id=strip-color-profile)
- [auto_rotate](https://docs.imgproxy.net/#/generating_the_url_advanced?id=auto-rotate)
- [filename](https://docs.imgproxy.net/#/generating_the_url_advanced?id=filename)
- [format](https://docs.imgproxy.net/#/generating_the_url_advanced?id=format)
- [return_attachment](https://docs.imgproxy.net/#/generating_the_url_advanced?id=return-attachment)
- [expires](https://docs.imgproxy.net/#/generating_the_url?id=expires)

_See [imgproxy URL format guide](https://docs.imgproxy.net/#/generating_the_url_advanced?id=processing-options) for more info._

### Complex processing options

Some of the processing options like `crop` or `gravity` may have multiple arguments, and you can define these arguments multiple ways:

#### Named arguments

First and the most readable way is to use a `Hash` with named arguments:

```ruby
Imgproxy.url_for(
  "http://images.example.com/images/image.jpg",
  crop: {
    width: 500,
    height: 600,
    gravity: {
      type: :nowe,
      x_offset: 10,
      y_offset: 5
    }
  }
)
# => .../c:500:600:nowe:10:5/...
```

All the arguments have the same names as in [imgproxy documentation](https://docs.imgproxy.net/#/generating_the_url_advanced?id=processing-options).

You can use named arguments even if the processing option is not supported by the gem. In this case the arguments won't be reordered nor formatted, so you should provide them in the same order and right the same way they should appear in the URL:

```ruby
Imgproxy.url_for(
  "http://images.example.com/images/image.jpg",
  unsupported: {
    arg1: 1,
    nested1: {
      arg2: 2,
      nested2: {
        arg3: 3
      }
    }
  }
)
# => .../unsupported:1:2:3/...
```

#### Unnamed arguments

The arguments of the complex options can be provided as an array of formatted values or even as a colon-separated string:

```ruby
Imgproxy.url_for(
  "http://images.example.com/images/image.jpg",
  crop: [500, 600, :nowe, 10, 5],
  trim: "10:aabbcc:1:1"
)
# => .../c:500:600:nowe:10:5/t:10:aabbcc:1:1/...
```

#### Single required argument

If a complex option has a single required argument, and you don't want to use the optional ones, you can just use its value:

```ruby
Imgproxy.url_for(
  "http://images.example.com/images/image.jpg",
  gravity: :nowe,
  trim: 10
)
# => .../g:nowe/t:10/...
```

### Base64 processing options arguments

Some of the processing options like `watermark_url` or `style` require their arguments to be base64-encoded. Good news is that imgproxy gem will encode them for you:

```ruby
Imgproxy.url_for(
  "http://images.example.com/images/image.jpg",
  watermark_url: "http://example.com/watermark.jpg",
  style: "color: rgba(255, 255, 255, .5)"
)
# => .../wmu:aHR0cDovL2V4YW1wbGUuY29tL3dhdGVybWFyay5qcGc/st:Y29sb3I6IHJnYmEoMjU1LCAyNTUsIDI1NSwgLjUp/...
```

### Special options:

- `base64_encode_url` — per-call redefinition of `base64_encode_urls` config.
- `escape_plain_url` — per-call redefinition of `always_escape_plain_urls` config.
- `use_short_options` — per-call redefinition of `use_short_options` config.

## Getting the image info

If you're a happy user of imgproxy Pro, you may find useful it's [Getting the image info](https://docs.imgproxy.net/#/getting_the_image_info) feature. imgproxy.rb allows you to easily generate info URLs for your images:

```ruby
# Framework-agnositic way
Imgproxy.info_url_for("http://images.example.com/images/image.jpg")
# Using Active Storage or Shrine
user.avatar.imgproxy_info_url

# You can also use base64_encode_url or escape_plain_url options
Imgproxy.info_url_for(
  "http://images.example.com/images/image.jpg",
  base64_encode_url: true
)
Imgproxy.info_url_for(
  "http://images.example.com/images/image.jpg",
  escape_plain_url: true
)
```

## URL adapters

By default, `Imgproxy.url_for` accepts only `String` and `URI` as the source URL, but you can extend that behavior by using URL adapters.

URL adapter is a simple class that implements `applicable?` and `url` methods. See the example below:

```ruby
class MyItemAdapter
  # `applicable?` checks if the adapter can extract
  # source URL from the provided object
  def applicable?(item)
    item.is_a? MyItem
  end

  # `url` extracts source URL from the provided object
  def url(item)
    item.image_url
  end
end

# ...

Imgproxy.configure do |config|
  config.url_adapters.add MyItemAdapter.new
end
```

**NOTE:** `Imgproxy` will use the first applicable URL adapter. If you need to add your adapter to the beginning of the list, use the `prepend` method instead of `add`.

**NOTE:** imgproxy.rb provides built-in adapters for Active Storage and Shrine that are automatically added when Active Storage or Shrine support is enabled.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/imgproxy/imgproxy.rb.

If you are having any problems with image processing of imgproxy itself, be sure to visit https://github.com/imgproxy/imgproxy first and check out the docs at https://github.com/imgproxy/imgproxy/blob/master/docs/.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Security Contact

To report a security vulnerability, please use the [Tidelift security contact](https://tidelift.com/security). Tidelift will coordinate the fix and disclosure.
