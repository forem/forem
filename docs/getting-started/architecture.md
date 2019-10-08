---
title: Architecture and Concepts
---

# A few high-level things to know

## We are a Ruby on Rails app

Ruby on Rails is a web framework heavy on conventions over configuration. All else equal we should try to follow Rails convention. We are currently on version 5.2.3, due for an upgrade to 6.x.x.

## We cache many content pages on the edge

- We use edge caching to serve many pages, meaning we do not go all the way to the server, meaning that on those pages we don't get access within the document to helper methods like `current_user`. A page is edge-cached through our CDN Fastly if the controller contains this line for the relevant action...

```
before_action :set_cache_control_headers
```

We also user server-side caching [Rails caching](https://guides.rubyonrails.org/caching_with_rails.html). Any time you see `Rails.cache` or `<%= cache ... %>`, this is code affected in production by caching.

## We use inline CSS and deferred scripts for usage performance improvements

To avoid blocking initial render, we put critical path CSS inline in the HTML and we user `defer` so the user is not waiting on extra assets. This means we have some constraints about how we can use JavaScript to affect the layout. In many cases, we should not attempt to do this.

## We attempt to reduce our bundle size

We use [PreactJs](https://preactjs.com/), a lightweight alternative to ReactJs, and generally, we try to reduce our bundle size with approaches such as [dynamic imports](https://dev.to/goenning/how-we-reduced-our-initial-jscss-size-by-67-3ac0).

## Worst technical debt

The biggest element of technical debt in our app are mostly on the frontend. We use both "old" (in the assets folder) and "new" (in the `app/javascript` folder) JavaScript, and could use some help migrating to the new parts.

We also have a sprawling CSS structure with few consistent rules.

## The algorithm behind the feed

The home feed is based on a combination of collective recent posts that are cached and delivered the same to everyone in the HTML, and additional articles fetched from an Algolia index after page load. To determine which posts a user sees, they are ranked based on the user's followed tags, followed users, and relative weights for each tag. Additional fetched articles also follow this general pattern.

Currently, the top post on the home feed, which must have a cover image, is shared among all users.

# General app concepts

## Articles (or posts)

This is the main high level content a user creates. An Article has many comments, taggings through acts-as-taggable gem, belongs to a user (and possibly an organization), and is generally the central core unit.

## Comments

Comments belong to articles (or podcasts, generally polymorphic). They belong first and foremost to the user in our architecture, which is reflected by the URL (`/username/tag-slug`) but they also fit in communal areas below other content. They are threaded but flatten out so that there is not infinite threading (e.g. once a discussion branch gets going, no more branching after a few).

## Tags

Tags help organize content, with rules for each tag. A tag is a de facto community with one or more moderators with privileges to determine what is appropriate for the tag. Some tags act as "flare" for posts so they show up more pronounced in the article when viewed from the index. Tags that belong as "flare" are currently defined in the `FlareTag` object. In cases of multiple flare tags, the flare displayed is determined by its hierarchy.

## ClassifiedListings (or listings)

Classified listings are similar to posts in some ways, but with more limitations. They are designed to be categorized into market areas. They also make use of tags.

## Organization

Users can belong to organizations, which have their own profile pages where posts can be published etc. This can be any group endeavor such as a company, an open source project, or any standalone publication on DEV

---

This is far from a complete view of the app, but it covers a few core concepts.
