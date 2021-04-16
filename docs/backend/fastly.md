---
title: Fastly
---

## What is Fastly?

[Fastly](https://www.fastly.com/) is a third party service we use for caching on
the edge. It allows us to scale up and serve our millions of visitors quickly
and efficiently.

If you want to learn more about we use Fastly, check out this
[talk](https://www.youtube.com/watch?v=Afy7H04X9Us) that one of our founders,
[@benhalpern](https://dev.to/ben), gave at RailsConf 2018 talking about how we
made our app so fast it went viral.

Fastly offers many different configurations (conditions,
[snippets](https://docs.fastly.com/vcl/vcl-snippets/about-vcl-snippets/), etc.).

## Snippets

Snippets, in general, are _"short blocks of VCL logic that can be included
directly in your service configurations. They're ideal for adding small sections
of code when you don't need more complex, specialized configurations that
sometimes require custom VCL."_

You can learn more about VCL snippets on
[Fastly's website](https://docs.fastly.com/vcl/vcl-snippets/about-vcl-snippets/)

### Adding query string parameters to a safe list

In the context of contributing, here's what you need to know about Fastly. In
order for our servers to receive any sort of query string parameters in a
request, they must first be marked as safe in Fastly. For example, if you're
creating a new API endpoint or updating an existing one to accept new
parameters, you'll need to update Fastly.

The reason we have a safe list of parameters in Fastly this way is so we don't
have to consider junk parameters when busting the caches. Check out our
[`EdgeCache` services](https://github.com/forem/forem/tree/main/app/services/edge_cache)
to see examples of this.

Previously this was a manual process done by an internal team member. Now we do
it programmatically using the Fastly
[gem](https://github.com/fastly/fastly-ruby).

### How it works

We created a new file, `config/fastly/safe_params_list.vcl`, to house all of the
safe params in Fastly.

If you need to update this list, simply update this file. It's as easy as that!
This is a VCL file and you'll see a little Regex checking for a list of safe
params.

_Fastly is not setup for development._

### In production

If you have Fastly configured in Production, all Fastly configs are updated
automatically when a production deploy goes out.

We do this by executing `bin/rails fastly:update_configs` in our
`release-tasks.sh` script.
