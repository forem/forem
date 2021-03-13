# A few high-level things to know

## We are a Ruby on Rails app

Ruby on Rails is a web framework heavy on conventions over configuration. All
else equal, we should try to follow Rails convention. We are currently on
version 6.x.x.

## We cache many content pages on the edge

To decrease loading time, we use edge-caching extensively. Taking advantage of
edge-caching means that we do not go all the way to the server to render every
page. However this means that, on cached pages, we don't have access to helper
methods like `current_user`. A page is edge-cached through our CDN
([Fastly][fastly]) if the controller contains this line for the relevant action:

```
before_action :set_cache_control_headers
```

We also use server-side caching: [Rails caching][rails_caching]. If you see
`Rails.cache` or `<%= cache ... %>`, this is code affected in production by
caching.

## Content precision

In some situations we may want more precise content than in others. Often when
we do not need a precise number, it offers an opportunity to either estimate
the content or bust the cache less frequently.

### Examples

- We use the `estimated_count` for a more efficient query of registered users on
the home page. We have deemed that this is probably close enough.
- On posts and comment trees without recent comments, we do not asynchronously fetch
the absolute latest individual reaction counts for logged-out users because this
number is likely to be correct without the async call, and if it is off-by-one, we
can make the choice that it is not important that it be more precise than this. 


## We Mostly defer scripts for usage performance improvements

To avoid blocking the initial render, we use the `defer` attribute to accelerate
page renders. This practice results in a faster page load, and doesn't leave
users waiting on heavy assets. However, this practice limits our ability to
manipulate layout with JavaScript. As a rule, you should avoid relying on
JavaScript for layout when working on Forem.

We have also experimented with different techniques involving inline CSS

## We attempt to reduce our bundle size

We use [PreactJS](/frontend/preact), a lightweight alternative to ReactJS, and
we try to reduce our bundle size with
[dynamic imports](/frontend/dynamic-imports).

## Service workers and shell architecture

We make use of serviceworkers to cache portions of the page.

Serviceworkers can be controlled in the `application` tab of Chrome.
Serviceworkers are a reverse proxy that runs in the browser in a non-blocking
thread, supported by most major browsers. You may want to disable or bypass
Serviceworkers in development while making changes to avoid having everything
cached.

## Worst technical debt

The most widespread elements of technical debt in this application reside on the
frontend. We use both the "old" approach (files in the `/assets` folder) and
"new" approach (files in the `app/javascript` folder) for loading JavaScript
into our Rails app.

We also have overgrown and inconsistent CSS. This is an area we'd love to see
contributions from the community.

We also have inconsistencies and issues with how we bust caching on the edge.
Ideally, we could practice resource-based purging as described in the [Fastly
Rails][fastly_rails] docs, but we bust specific URLs via `EdgeCache::Bust#call`.

## The algorithm behind the feed

The home feed is based on a combination of recent collective posts that are
cached and delivered the same to everyone in the HTML, and additional articles
fetched from an Elasticsearch index after page load. To determine which posts a
user sees, they are ranked based on the user's followed tags, followed users,
and relative weights for each tag. Additional fetched articles also follow this
general pattern.

Currently, the top post on the home feed, which must have a cover image, is
shared among all users.

## Inter-page navigation

Forem uses a variation of "instant click", via
[InstantClick](/frontend/instant-click), which swaps out page content instead of
making full-page requests. This approach is similar to the one used by the Rails
gem `Turbolinks`, but our approach is more lightweight. The library is modified
to work specifically with this Rails app and does not swap out reused elements
like the navigation bar or the footer. The code for this functionality is
viewable in `app/assets/javascripts/base.js.erb`.

There are a few caveats regarding this approach. Using our approach means a
non-trivial amount of functionality is reloaded on page change. A similar amount
of reloading occurs when using `window.InstantClick.on('change', someFunction)`.
This results in code that looks something like this:

```javascript
initPreview();
window.InstantClick.on('change', initPreview);
```

In some circumstances, this practice means the developer should pay special
attention to the declaration of variables and functions. JavaScript may behave
differently than expected.

Abstracting and removing these caveats is a long term goal, and contribution on
that front is welcome!

We use the parameter `i=i` (i for internal) to indicate to the backend that we
only want the "internal" version of the page (the one without the top nav and
footer, etc.)

## URLS and constraints

Because we use the top directory for user-generated pages, we need to be aware
of some constraints. `some-forem.com/sophia` could be a user, a page, an
organization, or a previously banished user. We allow users to retain two
redirects and should use `:moved_permanently` when a user changes their
username.

Because we may silently insert `?i=i` on the frontend to indicate internal nav,
we need to maintain that parameter if we are redirecting. We use the method
`redirect_permanently_to(location)` to encompass all of this behavior.

# General app concepts

## Articles (or posts)

Articles are the primary form of user generated content in the application. An
Article has many comments and taggings through the acts-as-taggable gem, belongs
to a single user (and possibly an organization), and is the core unit of
content.

## Collections (or series)

Although the source code refers to them as "collections" groups of articles are
referred to, throughout the user interface, as "series". They represent a
collection of articles relating to the same topic, indeed, a series.

## Comments

Comments belong to articles or other content (they are generally polymorphic).
They belong first and foremost to the user in our design, which is reflected by
the URL (`/username/tag-slug`), but they are present in communal areas of the
application. They are threaded, but they flatten out gradually to avoid
infinitely branching threads.

## Users

The user is the authorization/identity component of logging into the app. It is
also the public profile/authorship/etc. belonging to the people who use the app.

While "user" is a perfectly good technical name, it is a fairly cold way to
refer to humans, so we should prefer labeling people as members, or by their
name/username.

## Tags

Tags are used to organize user generated content. Each tag has a set of rules
which are used for moderation. Each tag is a de facto community complete with
community moderators.

Some tags behave as "flare," highlighting certain articles when viewed from the
index page. Tags that act as "flare" are defined in the `FlareTag` object. In
cases of multiple flare tags, the tag displayed is determined by its hierarchy.

## Listings

Listings are classified ads. They are similar to posts in some ways, but with
ore limitations. They are designed to be categorized into market areas. They
also make use of tags.

## Credits

Credits are the currency of the platform which users can use to buy listings.
The functionality of credits may be expanded in the future.

## Organizations

Users can belong to organizations, which have their own profile pages where
posts can be published etc. This can be any group endeavor such as a company, an
open source project, or any standalone publication on Forem.

## Reactions

Hearts, unicorns, and bookmarks. Reactions are the medium for displaying
appreciation for content. Bookmarks have the unique functionality of saving an
article in the user's reading list.

## Follows

How a user keeps track of the tags, users, or articles they care about. Follows
impact a user's home feed and notifications.

Follows can have a "score" which indicates how much a user wants to see the
element in their feed. Currently we only calculate these for tag follows, but it
could be expanded to users. The user can set an "explicit" score, and the system
also calculates an "implicit" score based on their activity.

## Roles

Through the "rolify" gem, users can have roles like "admin", etc. A role can
also be associated with a model or a model instance. Such as "moderator of
javascript tag"

## Organization

An organization is a collection of users who can author under one umbrella. An
organization could be a company or perhaps just a publication on-site.

## Notes

Notes are an internal tool admins can use to leave information about things.
Example: "This user was warned for spammy content".

## Pages

`Pages` in the [admin dashboard](/admin/) represent static pages to be served on
the site. Admins are in full control to create and customize them to their needs
using markdown or custom HTML. Pages are configured with a `slug` and they will
be served on either the `/page/slug` or `/slug` path.

In order to ease development of custom HTML Pages in local environments the rake
task `pages:sync` is available. It will listen to changes made to a local HTML
file and sync its contents to an existing Page in the database with the matching
`slug`.

Example: `rake pages:sync[slug,/absolute/path/to/file.html]`

---

This is far from a complete view of the app, but it covers a few core concepts.

[fastly]: https://www.fastly.com/
[rails_caching]: https://guides.rubyonrails.org/caching_with_rails.html
[fastly_rails]: https://github.com/fastly/fastly-rails
