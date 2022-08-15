# Feed Variants

This folder contains the feed variants that we have, are, or will be testing. By
convention the file's basename without extension is the name of the variant
(e.g. "./config/feed-variants/20220415-incumbent.json" encodes the variant named
`20220415-incumbent`).

There exists one variant, `original.json`, which is our fallback variant. This
fallback is performant and adequate for generating the feed for DEV.to. It is
present in case we need to quickly turn off an experiment. The name `original`
is the same as the `AbExperiment::ORIGINAL_VARIANT` constant.

**Do not remove `original.json` without consideration for how to rollback a feed
experiment.**

Variants are loaded into production as needed. That "need" is determined by the
configuration of the `./config/field_test.yml`. Once we load a variant into
production, we cache that variant (see
`Articles::Feeds::VariantAssembler.variants_cache`).

As part of our test suite we assemble and verify each defined variant.

## How to Make a Feed Variant

A feed variant is written in JSON format. A feed variant configures one or more
`Articles::Feeds::RelevancyLevers`. The variant configuration defines:

- The cases and fallback for each of the selected relevancy levers
- Optionally the sort order of the query results
- Optionally a few high level parameters.

The relevancy levers and their SQL query fragments are defined in
`Articles::Feeds::LEVER_CATALOG`. Any levers not configured for a variant are
omitted for that variant (but available for other variants).

The available sort order is also defined in `Articles::Feeds::LEVER_CATALOG`.

The high level parameters are defined in `Aritcles::Feeds::VariantQuery::Config`
and as of <2022-05-06 Fri> are:

- **_max_days_since_published_:** only consider articles that were published no
  more than the _max_days_since_published_.

- **_reseed_randomizer_on_each_request_:** when true, each time you call the
  query you will get different randomized numbers; when false, the resulting
  randomized numbers will be the same within a window of time.
