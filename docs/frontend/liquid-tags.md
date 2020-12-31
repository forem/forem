---
title: Liquid Tags
---

# Liquid Tags

Liquid tags are special elements of the
[Forem Markdown editor](https://dev.to/new).

They are custom embeds that are added via a `{% %}` syntax.
[Liquid](https://shopify.github.io/liquid/) is a templating language developed
by Shopify.

Liquid embeds are for tweets, like `{% tweet 765282762081329153 %}` or a Forem
user profile preview, like `{% user jess %}` etc.

They make for good community contributions because they can be extended and
improved consistently. It is truly how we extend the functionality of the
editor. At the moment, there could be a lot of work refactoring and improving
existing liquid tags, in addition to adding new ones.

Liquid tags are sort of like functions, which have a name and take arguments.
Develop them with that mindset in terms of naming things. They should be
documented but also intuitive. They should also be fairly flexible in the
arguments they take. Currently, this could use improvements.

_Note: Liquid tags are "compiled" when an article is saved. So you will need to
re-save articles to see HTML changes._

Here is a bunch of liquid tags supported on Forem:

```liquid
{% link https://dev.to/kazz/boost-your-productivity-using-markdown-1be %}
{% user jess %}
{% tag git %}
{% devcomment 2d1a %}
{% podcast https://dev.to/basecspodcast/s2e2--queues-irl %}
{% twitter 834439977220112384 %}
{% glitch earthy-course %}
{% github forem/forem %}
{% youtube dQw4w9WgXcQ %}
{% vimeo 193110695 %}
{% twitch ClumsyPrettiestOilLitFam %}
{% slideshare rdOzN9kr1yK5eE %}
{% codepen https://codepen.io/twhite96/pen/XKqrJX %}
{% stackblitz ball-demo %}
{% codesandbox ppxnl191zx %}
{% jsfiddle https://jsfiddle.net/link2twenty/v2kx9jcd %}
{% dotnetfiddle https://dotnetfiddle.net/PmoDip %}
{% replit @WigWog/PositiveFineOpensource %}
{% stackery deeheber lambda-layer-example layer-resource %}
{% nexttech https://nt.dev/s/6ba1fffbd09e %}
{% instagram BXgGcAUjM39 %}
{% speakerdeck 7e9f8c0fa0c949bd8025457181913fd0 %}
{% soundcloud https://soundcloud.com/user-261265215/dev-to-review-episode-1 %}
{% spotify spotify:episode:5V4XZWqZQJvbddd31n56mf %}
{% blogcast 1234 %}
{% kotlin https://pl.kotl.in/owreUFFUG %}
{% wikipedia https://en.wikipedia.org/wiki/Wikipedia %}
{% reddit https://www.reddit.com/r/aww/comments/ag3s4b/ive_waited_28_years_to_finally_havr_my_first_pet %}
```

## How liquid tags are developed

Liquid tags are a matter of parsing the "arguments" and serving relevant
JavaScript.

Liquid tags go in the `app/liquid_tags` folder. All liquid tags inherit from the
base, like so...

```ruby
class KotlinTag < LiquidTagBase
```

Each liquid tag contains an `initialize` method which takes arguments and calls
`super`. It also has a `render` method which calls the appropriate view.

```ruby
  def initialize(_tag_name, link, _parse_context)
    super
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split.first
    @embedded_url = KotlinTag.embedded_url(the_link)
  end

  def render(_context)
    ApplicationController.render(
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
https://github.com/forem/forem/pull/3801

### Restricting liquid tags by roles

To only allow users with specific roles to use a liquid tag, you need to define
a `VALID_ROLES` constant on the liquid tag itself. It needs to be an `Array` of
valid roles. For [single resource roles](/admin), it needs to be an `Array` with
the role and the resource. Here's an example:

```ruby
class NewLiquidTag < LiquidTagBase
  VALID_ROLES = [
    :admin,
    [:restricted_liquid_tag, LiquidTags::UserSubscriptionTag]
  ].freeze
end
```

Here we are saying that the `UserSubscriptionTag` is only usable by users with
the `admin` role or with a role of `:restricted_liquid_tag` and a specified
resource of `LiquidTags::UserSubscriptionTag`.

`LiquidTags::UserSubscriptionTag` is a resource model so we that can play nicely
with the [Rolify][rolify] gem. See [/admin](/admin) for more information.

**REMINDER: if you do not define a `VALID_ROLES` constant, the liquid tag will
be usable by all users by default.**

### Restricting liquid tags by context

Context, in terms of a liquid tag, is _where_ a liquid tag is being used (i.e.
`Article`, `Comment`, etc.). In other words, if you want to make a liquid tag
that can only be used in articles, you need to restrict the liquid tag by
context.

To do this you need to add a `VALID_CONTEXTS` constant on the liquid tag itself.
It needs to be an `Array` of class names that are valid. For example, to
restrict a liquid tag to only be usable in articles you would do:

```ruby
class NewLiquidTag < LiquidTagBase
  VALID_CONTEXTS = %w[Article].freeze
end
```

**REMINDER: if you do not define a `VALID_CONTEXTS` constant the liquid tag will
be usable in all contexts by default.**

[rolify]: https://github.com/RolifyCommunity/rolify
