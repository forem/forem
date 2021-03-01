# Compatibility

To go along with effective administration and putting user security and
well-being first, for a Forem to be most useful, it maximizes its technical
compatibility.

Compatibility means:

- Staying updated. We need to maintain overall compatibility by keeping the
  ecosystem close to the latest version as proactively as we can.
- Maintaining all programmatic interfaces, whether they be the
  [API](https://api.forem.com) or Forem meta tags which can be consumed for
  Forem validation.
- Maintaining human interfaces which allow users to find where they need to go
  and conduct all necessary customizations.
- Maintaining great performance such that the web-based Forem ecosystem can
  provide a great experience in all network conditions and in comparison to more
  closed ecosystems.

## Meta tags

The canonical meta tags which are expected to be present as a component of
validation are as follows:

```html
<meta property="forem:name" content="My great friends" />
<meta property="forem:logo" content="https://mygreatfriends.com/logo.png" />
<meta property="forem:domain" content="mygreatfriends.com" />
```

This list may evolve over time. If you want to propose a new meta tag which
could improve the efficacy of an ecosystem app, please feel free to open an
issue or a discussion on [forem.dev](https://forem.dev).
