# Feed Configuration

Welcome to the technical documentation of the Feed Configuration. In this
document we'll introduce the historical context, provide a glossary of terms,
delve into the high-level goals of the configurations, and describe any present
constraints.

## Historical Documents

- The
  [Articles::Feeds::WeightedQueryStrategy](https://github.com/forem/forem/blob/de2edee07d824a34e5c5445d455b1f8086bd127d/app/services/articles/feeds/weighted_query_strategy.rb)
  is the precursor to the more robust feed configuration. It provides hints as
  to how we'll structure the feed configuration.
- [These Are the [Feed] Levers I Know I Know - Forem Team 🌱](https://dev.to/devteam/these-are-the-feed-levers-i-know-i-know-3jj7)
- [Creating a Catalog of Feed Levers and Configurations - Forem Team 🌱](https://forem.team/jeremy/creating-a-catalog-of-feed-levers-and-configurations-nnk)
- On <2022-04-11 Mon>,
  [Jeremy, Jennie, Ella, and Michael T met over Zoom to talk through the current feed](https://forem.team/jeremy/lets-talk-about-the-feed-baby-54b1).

## Glossary

- **_Feed Experiment_:** A _feed experiment_ is the currently implemented set of
  _feed strategies_ - current configurations we're using to generate feeds
- **_Feed Strategy_:** a configuration of _levers_ and _relevancy factors_,
  which can be used to generate the _relevancy feed_.
- **_Lever_:** A _lever_ is a specific attribute we're querying from the
  database.
- **_Lever Range_:** The _lever range_ is the potential range of values that the
  underlying _lever_ query will emit; for example integers greater than or equal
  to 0.
- **_Relevancy Factor_:** The _relevancy factor_ maps the _lever range_ to a
  rational number between 0 and 1.
- **_Relevancy Feed_:** The _relevancy feed_ (or for this document the _feed_)
  builds the list of articles a user sees on the homepage of a Forem.
- **_Relevancy Score_:** Each article is assigned a _relevancy score_ based on
  the _lever_ configuration of the current _feed strategy_. It is the product of
  all applicable _relevancy factors_ for each of the _levers_ in the _feed
  strategy_.

At a future point, we might allow for the site creators to pick one or more feed
strategies for the _relevancy feed_ and even allow a member to specify their
feed. It is possible that we would adjust the UI so that the feed formats
(Relevant, Recent, and Top) also include things like "Active Discussions" or
other emergent _feed strategies_.

## Configuration

There are three layers of configuration, presented working from the inside out.

1.  Lever
2.  Feed Strategy
3.  Feed Experiment

### Lever Configuration

Each _lever_ requires engineering time to create and define. This involves:

- Defining the programmatic key for the lever.
- Writing the human readable label.
- Describing the purpose of the lever.
- Creating the SQL clause fragments (e.g. _select_, optional _joins_, and _group
  by_), and documenting the _lever range_.
- Defining if this is a lever that requires the user to be signed in.

This may also require adding new variables that we pass to the SQL parameter
substitution process. (see Experience lever factor).

I believe the goal is to avoid changing the SQL implementation details of a
lever; we would instead create a new lever. This way we can have consistent
documentation for a given lever.

### Feed Strategy

Each _feed strategy_ need not require engineering time to create and define.
This involves:

- Defining the programmatic key for the _feed strategy_.
- Writing the human readable label.
- Writing any notes around the _feed strategy_.
- Defining which _lever_ this _feed strategy_ incorporates.
- For each _lever_,
  - Mapping the elements within the _lever range_ to the desired _relevancy
    factor_.
  - Defining the fallback _relevancy factor_.
  - Describing the intention of this mapping and fallback.

From an application stand-point we want to run the queries for each _feed
strategy_ (to ensure valid SQL).

### Feed Experiment

At any given time, we are running one _feed experiment_. The _feed experiment_
comprises one or more _feed strategies_ and defines the probability of a user
being assigned to each of those feeds; see our
[AbExperiment](https://github.com/forem/forem/blob/main/app/models/ab_experiment.rb).
We will need to uniquely name each _feed experiment_ so we can collectively
document both intention and observations.

## Environments and Constraints

This section outlines the current (as of <2022-04-12 Tue>) constraints of the
system.

While the application is running, either in _production_ or under a request or
integration test, we should only load _feed strategies_ that are part of a _feed
experiment_ and/or available for a Creator to select.

To expose a new _feed strategy_ to a production instance will require a deploy
of that instance. At a future point, we may look to allowing uploads of _feed
strategies_ but that is not the current path.

Changing from one _feed experiment_ to another will require a new deploy. At a
future point we might allow for live changes of the _feed experiment_ but that
is outside the scope of present considerations.

Each _feed strategy_ will be tested as part of unit testing; to ensure it
generates valid SQL.

Each _feed lever_ will be tested as part of unit testing to ensure it is well
crafted.

One consideration is that the _relevancy feed_ should include a _published_at_
constraint. This can generate a large and potentially expensive query, so we
want to discard older articles from the relevancy.

What is the recommended size of that _published_at_ constraint? It is a function
of the average number of posts per week. A more active Forem, such as
[DEV](https://dev.to) would want to limit this _published_at_ constraint to
around 2 weeks. A less active one could limit to 2 months.
