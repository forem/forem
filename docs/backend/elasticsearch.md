---
title: Elasticsearch
---

# What is [Elasticsearch](https://www.elastic.co/what-is/elasticsearch)?

> Elasticsearch is a distributed, open-source search and analytics engine for
> all types of data, including textual, numerical, geospatial, structured, and
> unstructured. Elasticsearch is built on Apache Lucene and was first released
> in 2010 by Elastic.

# How Forem uses Elasticsearch

### Searchable Models

At Forem we use Elasticsearch for all of our user-facing searching needs. Models
that are searched using Elasticsearch are:

- Tags
- Listings
- Chat Channels
- Users
- Podcast Episodes
- Comments
- Articles

### Index Setup

The above models are organized in Elasticsearch in different
[indexes](https://www.elastic.co/blog/what-is-an-elasticsearch-index) to make
searching more accurate and performant. The index breakdown is:

- Tags index -> Tags
- Listings index -> Listings
- Chat Channel Membership index -> Chat Channels
- User's index -> Users
- Feed Content index -> Podcast Episodes, Comments, and Articles

You will notice that Podcast Episodes, Comments, and Articles all share the same
index. This allows us to search and aggregate across all of these documents at
the same time. These documents also share a lot of similar fields so putting
them in the same index made sense. In the future, depending on our search needs
this index structure might change.

Each index that is listed above has a corresponding
[mapping](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)
that defines what fields can and cannot be indexed to it. These mappings are
similar to a db schema. In our case, all of our index mappings are defined as
[`strict`](https://www.elastic.co/guide/en/elasticsearch/reference/current/dynamic.html#dynamic)
which means if we try to index a field that is not defined it will throw an
error. Mappings for each index can be found in
`app/config/elasticsearch/mappings`.

### Indexing documents into Elasticsearch

In order to index the data from Postgres into Elasticsearch, we rely on
callbacks in our ActiveRecord models. Whenever a model is created or updated we
use an `after_commit` callback to enqueue a `Search::IndexWorker` which handles
indexing the document into Elasticsearch. In order to translate our ActiveRecord
data to Elasticsearch we use serializers. Each model has its own serializer
which can be found in `app/serializers/search`

### Searching Elasticsearch

Once the documents are in Elasticsearch then we can search for them. This is
handled by code in our `app/services/search` directory. Here you will see a
collection of classes used to help us index and search documents in
Elasticsearch. The nested `query_builders` directory contains all the logic we
need to help us build complex search queries to send to Elasticsearch.

# Working With Elasticsearch

## How to add a new field to Elasticsearch

When adding a new field to Elasticsearch here are the steps you have to follow:

1. Add field to mapping by editing the appropriate JSON file in
   `app/config/elasticsearch/mappings`. If you plan to test locally you will
   need to run `bin/setup` to update your local Elasticsearch mappings.
2. Add field to serializer for model located in `app/serializers/search`.
3. If the new field needs to be backfilled write a DataUpdateScript to reindex
   all affected models so the field is available and populated in Elasticsearch
4. DEPLOY - Before you can start using a new field you need to ensure that it is
   added to Elasticsearch and populated properly. The worker that runs the
   DataUpdateScript will run 5 min after a deploy completes. This means you have
   to deploy the code for adding the field separate from the code that will use
   it.
5. Add code to search for your new field. You likely will need to update the
   allowed params in the searches controller as well as the pertinent query
   builder.
6. DEPLOY new search code
7. DONE!
