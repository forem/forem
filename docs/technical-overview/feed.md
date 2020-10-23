# "The feed"

The Forem feed is perhaps _the_ core functionality of the service. It's an
adaptation of a concept popularized by other social platforms in the past two
decades, and it is something we need to develop with care in a way that empowers
individual communities and users.

The core nature of "the feed" is that it needs to evolve and be flexible. We
will learn new ideas over time. We need to take into account metrics, but also
question the relevance and "goodness" of certain metrics. We want folks finding
fulfilling and enriching content, not necessarily addictive content.

However, we are in the fairly naive early days of the feed, so primarily it is a
matter of flexibility and experimentation.

### Feed style

Each Forem can have a feed style set by the admin of that community (originally
implemented [in a PR from mid-2020](https://github.com/forem/forem/pull/8721)).

Currently, we have two styles: `rich` and `basic`. Where `rich` always displays
the cover image in the feed, `basic` hides it from the feed view.

Over time, we'll improve and expand our feed style options.

### Feed strategy

Each Forem can have a feed strategy set by the admin of that community
(originally implemented
[in a late-2020 PR](https://github.com/forem/forem/pull/10245)). Currently, we
have two strategies: `basic` and `large_forem_experimental`. The "experimental"
component dictates that there is some split testing, but generally these are
just cues for an underlying algorithm which can change liberally.

The feed endpoint is driven by the `feeds_controller` and the content is found
in objects such as `Articles::Feeds::Basic`. We should lean toward adaptability
and versatility in the long run here, even if we are just at the beginning of
this transparent journey.
