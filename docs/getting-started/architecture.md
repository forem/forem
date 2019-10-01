---
title: Architecture and Concepts
---

# A few high level things to know

## We are a Ruby on Rails app

Ruby on Rails is a web framework heavy on conventions over configuration. All else equal we should try to follow Rails convention. We are currently on version 5.2.3, due for an upgrade to 6.x.x.

## We cache many content pages on the edge

- We use edge caching to serve many pages, meaning we do not go all the way to the server, meaning that on those pages we don't get access within the document to helper methods like `current_user`. A page is edge-cached through our CDN Fastly if the controller contains this line for the relevant action...

```
before_action :set_cache_control_headers
```

We also user server-side caching [Rails caching](https://guides.rubyonrails.org/caching_with_rails.html). Any time you see `Rails.cache` or `<%= cache ... %>`, this is code affected in production by caching. 

## We use inline CSS and defered scripts for usage performance improvements

To avoid blocking initial render, we put critical path CSS inline in the HTML and we user `defer` so the user is not waiting on extra assets. This means we have some constraints about how we can use JavaScript to affect the layout. In many cases we should not attempt to do this.

## We attempt to reduce our bundle size

We use [PreactJs](https://preactjs.com/), a lightweight alternative to ReactJs, and generally we try to reduce our bundle size with approaches such as [dynamic imports](https://dev.to/goenning/how-we-reduced-our-initial-jscss-size-by-67-3ac0).

## Worst technical debt

The biggest element of technical debt in our app are mostly on the frontend. We use both "old" (in the assets folder) and "new" (in the `app/javascript` folder) JavaScript, and could use some help migrating to the new parts.

We also have a sprawling CSS structure with few consistent rules.

## The algorithm behind the feed

The home feed is based on a combination of collective recent posts that are cached and delivered the same to everyone in the HTML, and additional articles fetched from an Algolia index after page load. To determine which posts a user sees, they are ranked based on the user's followed tags, followed users, and relative weights for each tag. Additional fetched articles also follow this general pattern.

Currently the top post on the home feed, which must have a cover image, is shared among all users.