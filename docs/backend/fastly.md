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

## Adding query string parameters to a safe list

In the context of contributing, here's what you need to know about Fastly. In
order for our servers to receive any sort of query string parameters in a
request, they must first be marked as safe in Fastly. For example, if you're
creating a new API endpoint or updating an existing one to accept new
parameters, you'll need to update Fastly.

The reason we have a safe list of parameters in Fastly this way is so we don't
have to consider junk parameters when busting the caches. Check out our
[`CacheBuster`](https://github.com/thepracticaldev/dev.to/blob/master/app/labor/cache_buster.rb)
to see examples of this.

Previously this was a manual process done by an internal team member. Now we do
it programmatically using the Fastly
[gem](https://github.com/fastly/fastly-ruby) as of
[this pr](https://github.com/thepracticaldev/dev.to/pull/7279).

## How it works

We created a new file, `config/fastly/safe_params.yml`, to house all of the safe
params in Fastly.

If you need to update this list, simply update this file. It's as easy as that!

_Fastly is not setup for development._

## In production

If you have Fastly configured in Production and have a similar custom VCL script
to list safe query string params, make sure you've set the
`FASTLY_SAFE_PARAMS_SNIPPET_NAME` ENV variable with the name of the VCL snippet
you have configured in Fastly.

Safe params on Fastly are updated automatically when a production deploy goes
out unless this key is not set (i.e. you don't have a similar custom VCL setup).

We do this by executing `bin/rails fastly:update_safe_params` in our
`release-tasks.sh` script.
