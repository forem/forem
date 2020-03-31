---
title: Liquid Tags
---

# Liquid Tags

Liquid tags are special elements of the
[DEV Markdown editor](https://dev.to/new).

They are custom embeds that are added via a `{% %}` syntax.
[Liquid](https://shopify.github.io/liquid/) is a templating language developed
by Shopify.

Liquid embeds are for tweets, like `{% tweet 765282762081329153 %}` or a DEV
user profile preview, like `{% user jess %}` etc.

They make for good community contributions because they can be extended and
improved consistently. It is truly how we extend the functionality of the
editor. At the moment, there could be a lot of work refactoring and improving
existing liquid tags, in addition to adding new ones.

Liquid tags are sort of like functions, which have a name and take arguments.
Develop them with that mindset in terms of naming things. They should be
documented but also intuitive. They should also be fairly flexible in the
arguments they take. Currently, this could use improvements.

Liquid tags are "compiled" when an article is saved. So you will need to re-save
articles to see HTML changes.

Here is a bunch of liquid tags supported on DEV:

```liquid
{% link https://dev.to/kazz/boost-your-productivity-using-markdown-1be %}
{% user jess %}
{% tag git %}
{% devcomment 2d1a %}
{% podcast https://dev.to/basecspodcast/s2e2--queues-irl %}
{% twitter 834439977220112384 %}
{% glitch earthy-course %}
{% github thepracticaldev/dev.to %}
{% youtube dQw4w9WgXcQ %}
{% vimeo 193110695 %}
{% slideshare rdOzN9kr1yK5eE %}
{% codepen https://codepen.io/twhite96/pen/XKqrJX %}
{% stackblitz ball-demo %}
{% codesandbox ppxnl191zx %}
{% jsfiddle https://jsfiddle.net/link2twenty/v2kx9jcd %}
{% replit @WigWog/PositiveFineOpensource %}
{% nexttech https://nt.dev/s/6ba1fffbd09e %}
{% instagram BXgGcAUjM39 %}
{% speakerdeck 7e9f8c0fa0c949bd8025457181913fd0 %}
{% soundcloud https://soundcloud.com/user-261265215/dev-to-review-episode-1 %}
{% spotify spotify:episode:5V4XZWqZQJvbddd31n56mf %}
{% blogcast 1234 %}
{% kotlin https://pl.kotl.in/owreUFFUG %}
```

## How liquid tags are developed

Liquid tags are a matter of parsing the "arguments" and serving relevant
JavaScript.

Liquid tags go in the `app/liquid_tags` folder. All liquid tags inherit from the
base, like so...

```ruby
class KotlinTag < LiquidTagBase
```

Each liquid tag contains an `initialize` method which takes arguments and a
`render` method which calls the appropriate view.

```ruby
  def initialize(tag_name, link, tokens)
    super
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split(" ").first
    @embedded_url = KotlinTag.embedded_url(the_link)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        url: @embedded_url
      }
    )
  end
```

View files can be found in `app/views/liquids`.

Each new liquid tag should be accompanied by instructions in
`app/views/pages/_editor_guide_text.html.erb`.

Liquid Tags should also be accompanied by tests in `spec/liquid_tags` which
confirm expected behavior.

Some Liquid Tags are constructed using HTML and CSS within the app, and some are
constructed by displaying an iframe of an external site.

CSS for Liquid Tags are found in `app/assets/stylesheets/ltags`. Liquid tag
classes should generally be prepended by `ltag__`. e.g. `ltag__tag__content`
etc.

Here is an example of a good Liquid Tag pull request...
https://github.com/thepracticaldev/dev.to/pull/3801
