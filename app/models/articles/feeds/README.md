# Feed Configuration

Welcome to the technical documentation of the Feed Configuration. It's
structured as an index pointing you to related files.

## Historical Documents

- The
  [Articles::Feeds::WeightedQueryStrategy](https://github.com/forem/forem/blob/de2edee07d824a34e5c5445d455b1f8086bd127d/app/services/articles/feeds/weighted_query_variant.rb)
  is the precursor to the more robust feed configuration.
- [This post](https://dev.to/devteam/these-are-the-feed-levers-i-know-i-know-3jj7)
  walked through the meaning of each of the initial relevancy levers.

In addition there are two code walk throughs explaining the pull requests that
introduced the VariantQuery:

- [Introducing the concepts](https://www.loom.com/share/857cea3698f44a4f876a01fb4e72552c)
- [Walk through of code connecting concepts to production](https://www.loom.com/share/31f06224b61c4f7ca01c85e1fe0c239a)

## So You Want to Change the Relevancy Feed

The [forem/forem#17406 pull request](https://github.com/forem/forem/pull/17406)
contains an example of configuring a
[VariantQuery](https://github.com/forem/forem/blob/main/app/services/articles/feeds/variant_query.rb)
You can also read the
[config/feed-variants/README.md](https://github.com/forem/forem/blob/main/config/feed-variants/README.md)
for further context.

## Understanding the Variant Query

In
[Diving into Dev's Relevancy Feed Builder](https://dev.to/devteam/diving-into-devs-relevancy-feed-builder-30m6)
we explained the conceptual implementation; providing a conceptual entity
relationship and sequence diagrams.

The key thing to understand is as follows: We create a SQL statement that
calculates a `relevancy_score` for a given user and each article in the Forem
instance. The higher the article's `relevancy_score`, the closer that article
will be to the top of the feed.
