---
title: Other Tools
---

# Miscellaneous

## Foreman

We use [Foreman](https://github.com/ddollar/foreman) to manage our application
through `Procfile` and `Procfile.dev`. As the
[documentation](https://github.com/ddollar/foreman/blob/master/README.md) points
out,

> Ruby users should take care _not_ to install foreman in their project's
> `Gemfile`. See this
> [wiki article](https://github.com/ddollar/foreman/wiki/Don't-Bundle-Foreman)
> for more details.

Instead install Foreman globally with the following command:

```sh
$ gem install foreman
```
