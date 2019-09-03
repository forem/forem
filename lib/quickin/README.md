# Quickin
This is a [Rails Engine](https://guides.rubyonrails.org/engines.html) that
intentionally isolates some dangerous code.

In this application, if you are in the development environment, this gem will
allow you to quickly login as a user by hitting the `/quickin` route.

You can pass an ID parameter to the route if you want to get a user by ID:

```
localhost:3000/quickin?id=4 # Login as the user with an id of 4
```

This should probably not be used at all outside of the dev.to application,
it's generally pretty hacky, but is useful due to the unique nature of the
auth system used by Dev.to.

Ideally, it can be replaced easily by a development-only masquerade feature.

## License
The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
