# Inline SVG

![Unit tests](https://github.com/jamesmartin/inline_svg/workflows/Ruby/badge.svg)
![Integration Tests](https://github.com/jamesmartin/inline_svg/workflows/Integration%20Tests/badge.svg)

Styling a SVG document with CSS for use on the web is most reliably achieved by
[adding classes to the document and
embedding](http://css-tricks.com/using-svg/) it inline in the HTML.

This gem adds Rails helper methods (`inline_svg_tag` and `inline_svg_pack_tag`) that read an SVG document (via Sprockets or Webpacker, so works with the Rails Asset Pipeline), applies a CSS class attribute to the root of the document and
then embeds it into a view.

Inline SVG supports:

- [Rails 5](http://weblog.rubyonrails.org/2016/6/30/Rails-5-0-final/) (from [v0.10.0](https://github.com/jamesmartin/inline_svg/releases/tag/v0.10.0))
- [Rails 6](https://weblog.rubyonrails.org/2019/4/24/Rails-6-0-rc1-released/) with Sprockets or Webpacker (from [v1.5.2](https://github.com/jamesmartin/inline_svg/releases/tag/v1.5.2)).
- [Rails 7](https://weblog.rubyonrails.org/2021/12/6/Rails-7-0-rc-1-released/)

Inline SVG no longer officially supports Rails 3 or Rails 4 (although they may still work). In order to reduce the maintenance cost of this project we now follow the [Rails Maintenance Policy](https://guides.rubyonrails.org/maintenance_policy.html).

## Changelog

This project adheres to [Semantic Versioning](http://semver.org). All notable changes are documented in the
[CHANGELOG](https://github.com/jamesmartin/inline_svg/blob/master/CHANGELOG.md).

## Installation

Add this line to your application's Gemfile:

    gem 'inline_svg'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install inline_svg

## Usage

```ruby
# Sprockets
inline_svg_tag(file_name, options={})

# Webpacker
inline_svg_pack_tag(file_name, options={})
```

_**Note:** The remainder of this README uses `inline_svg_tag` for examples, but the exact same principles work for `inline_svg_pack_tag`._

The `file_name` can be a full path to a file, the file's basename or an `IO`
object. The
actual path of the file on disk is resolved using
[Sprockets](://github.com/sstephenson/sprockets) (when available), a naive file finder (`/public/assets/...`) or in the case of `IO` objects the SVG data is read from the object.
This means you can pre-process and fingerprint your SVG files like other Rails assets, or choose to find SVG data yourself.

Here's an example of embedding an SVG document and applying a 'class' attribute:

```erb
<html>
  <head>
    <title>Embedded SVG Documents<title>
  </head>
  <body>
    <h1>Embedded SVG Documents</h1>
    <div>
      <%= inline_svg_tag "some-document.svg", class: 'some-class' %>
    </div>
  </body>
</html>
```

Here's some CSS to target the SVG, resize it and turn it an attractive shade of
blue:

```css
.some-class {
  display: block;
  margin: 0 auto;
  fill: #3498db;
  width: 5em;
  height: 5em;
}
```

## Options

key                     | description
:---------------------- | :----------
`id`                    | set a ID attribute on the SVG
`class`                 | set a CSS class attribute on the SVG
`style`                 | set a CSS style attribute on the SVG
`data`                  | add data attributes to the SVG (supply as a hash)
`size`                  | set width and height attributes on the SVG <br/> Can also be set using `height` and/or `width` attributes, which take precedence over `size` <br/> Supplied as "{Width} * {Height}" or "{Number}", so "30px\*45px" becomes `width="30px"` and `height="45px"`, and "50%" becomes `width="50%"` and `height="50%"`
`title`                 | add a \<title\> node inside the top level of the SVG document
`desc`                  | add a \<desc\> node inside the top level of the SVG document
`nocomment`             | remove comment tags from the SVG document
`preserve_aspect_ratio` | adds a `preserveAspectRatio` attribute to the SVG
`view_box`              | adds a `viewBox` attribute to the SVG
`aria`                  | adds common accessibility attributes to the SVG (see [PR #34](https://github.com/jamesmartin/inline_svg/pull/34#issue-152062674) for details)
`aria_hidden`           | adds the `aria-hidden=true` attribute to the SVG
`fallback`              | set fallback SVG document

Example:

```ruby
inline_svg_tag(
  "some-document.svg",
  id: 'some-id',
  class: 'some-class',
  data: {some: "value"},
  size: '30% * 20%',
  title: 'Some Title',
  desc: 'Some description',
  nocomment: true,
  preserve_aspect_ratio: 'xMaxYMax meet',
  view_box: '0 0 100 100',
  aria: true,
  aria_hidden: true,
  fallback: 'fallback-document.svg'
)
```

## Accessibility

Use the `aria: true` option to make `inline_svg_tag` add the following
accessibility (a11y) attributes to your embedded SVG:

* Adds a `role="img"` attribute to the root SVG element
* Adds a `aria-labelled-by="title-id desc-id"` attribute to the root SVG
  element, if the document contains `<title>` or `<desc>` elements

Here's an example:

```erb
<%=
  inline_svg_tag('iconmonstr-glasses-12-icon.svg',
    aria: true, title: 'An SVG',
    desc: 'This is my SVG. There are many like it. You get the picture')
%>
```

```xml
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" \
  role="img" aria-labelledby="bx6wix4t9pxpwxnohrhrmms3wexsw2o m439lk7mopdzmouktv2o689pl59wmd2">
  <title id="bx6wix4t9pxpwxnohrhrmms3wexsw2o">An SVG</title>
  <desc id="m439lk7mopdzmouktv2o689pl59wmd2">This is my SVG. There are many like it. You get the picture</desc>
</svg>
```

***Note:*** The title and desc `id` attributes generated for, and referenced by, `aria-labelled-by` are one-way digests based on the value of the title and desc elements and an optional "salt" value using the SHA1 algorithm. This reduces the chance of `inline_svg_tag` embedding elements inside the SVG with `id` attributes that clash with other elements elsewhere on the page.

## Custom Transformations

The transformation behavior of `inline_svg_tag` can be customized by creating custom transformation classes.

For example, inherit from `InlineSvg::CustomTransformation` and implement the `#transform` method:

```ruby
# Sets the `custom` attribute on the root SVG element to supplied value
# Remember to return a document, as this will be passed along the transformation chain

class MyCustomTransform < InlineSvg::CustomTransformation
  def transform(doc)
    with_svg(doc) do |svg|
      svg["custom"] = value
    end
  end
end
```

Add the custom configuration in an initializer (E.g. `./config/initializers/inline_svg.rb`):

```ruby
# Note that the named `attribute` will be used to pass a value to your custom transform
InlineSvg.configure do |config|
  config.add_custom_transformation(attribute: :my_custom_attribute, transform: MyCustomTransform)
end
```

The custom transformation can then be called like so:
```haml
%div
  = inline_svg_tag "some-document.svg", my_custom_attribute: 'some value'
```

In this example, the following transformation would be applied to a SVG document:

```xml
<svg custom="some value">...</svg>
```

You can also provide a default_value to the custom transformation, so even if you don't pass a value it will be triggered

```ruby
# Note that the named `attribute` will be used to pass a value to your custom transform
InlineSvg.configure do |config|
  config.add_custom_transformation(attribute: :my_custom_attribute, transform: MyCustomTransform, default_value: 'default value')
end
```

The custom transformation will be triggered even if you don't pass any attribute value
```haml
%div
  = inline_svg_tag "some-document.svg"
  = inline_svg_tag "some-document.svg", my_custom_attribute: 'some value'
```

In this example, the following transformation would be applied to a SVG document:

```xml
<svg custom="default value">...</svg>
```

And

```xml
<svg custom="some value">...</svg>
```

Passing a `priority` option with your custom transformation allows you to
control the order that transformations are applied to the SVG document:

```ruby
InlineSvg.configure do |config|
  config.add_custom_transformation(attribute: :custom_one, transform: MyCustomTransform, priority: 1)
  config.add_custom_transformation(attribute: :custom_two, transform: MyOtherCustomTransform, priority: 2)
end
```

Transforms are applied in ascending order (lowest number first).

***Note***: Custom transformations are always applied *after* all built-in
transformations, regardless of priority.

## Custom asset file loader

An asset file loader returns a `String` representing a SVG document given a
filename. Custom asset loaders should be a Ruby object that responds to a
method called `named`, that takes one argument (a string representing the
filename of the SVG document).

A simple example might look like this:

```ruby
class MyAssetFileLoader
  def self.named(filename)
    # ... load SVG document however you like
    return "<svg>some document</svg>"
  end
end
```

Configure your custom asset file loader in an initializer like so:

```ruby
InlineSvg.configure do |config|
  config.asset_file = MyAssetFileLoader
end
```

## Caching all assets at boot time

When your deployment strategy prevents dynamic asset file loading from disk it
can be helpful to cache all possible SVG assets in memory at application boot
time. In this case, you can configure the `InlineSvg::CachedAssetFile` to scan
any number of paths on disks and load all the assets it finds into memory.

For example, in this configuration we load every `*.svg` file found beneath the
configured paths into memory:

```ruby
InlineSvg.configure do |config|
  config.asset_file = InlineSvg::CachedAssetFile.new(
    paths: [
      "#{Rails.root}/public/path/to/assets",
      "#{Rails.root}/public/other/path/to/assets"
    ],
    filters: /\.svg/
  )
end
```

**Note:** Paths are read recursively, so think about keeping your SVG assets
restricted to as few paths as possible, and using the filter option to further
restrict assets to only those likely to be used by `inline_svg_tag`.

## Missing SVG Files

If the specified SVG file cannot be found a helpful, empty SVG document is
embedded into the page instead. The embedded document contains a single comment
displaying the filename of the SVG image the helper tried to render:

```html
<svg><!-- SVG file not found: 'some-missing-file.svg' --></svg>
```

You may apply a class to this empty SVG document by specifying the following
configuration:

```rb
InlineSvg.configure do |config|
  config.svg_not_found_css_class = 'svg-not-found'
end
```

Which would instead render:

```html
<svg class='svg-not-found'><!-- SVG file not found: 'some-missing-file.svg' --></svg>
```

Alternatively, `inline_svg_tag` can be configured to raise an exception when a file
is not found:

```ruby
InlineSvg.configure do |config|
  config.raise_on_file_not_found = true
end
```

## Contributing

1. Fork it ( [http://github.com/jamesmartin/inline_svg/fork](http://github.com/jamesmartin/inline_svg/fork) )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Please write tests for anything you change, add or fix.
There is a [basic Rails
app](http://github.com/jamesmartin/inline_svg_test_app) that demonstrates the
gem's functionality in use.
