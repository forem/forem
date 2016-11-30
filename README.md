# This is the public repo for dev.to

The core purpose of this repo is for feedback and discussion about the platform. Issues are available for this purpose. This repo will evolve once we foray further into open source activity. We want the platform to eventually be 95% open source, even the parts that are not extracted for re-use. The plan is to release our whole codebase eventually and keeping a few private APIs available for necessary purposes.

We are not nearly there yet, so for now, let's just use this to discuss features and provide feedback.

## Current functionality
Host technical blog posts and helpful articles for developers. Publishing is fairly simple and uses a markdown editor that is fully copy and paste compatible with Jekyll, including [front matter](https://jekyllrb.com/docs/frontmatter/)

## Feature roadmap

- Comments and upvotes
- Richer markdown experience
- Smarter "next article" suggestions, and "related podcats"
- Other stuff 🤔

## The road to open source
The core website is a Rails application. Getting this generally open sourced will be a matter of diligently walking through the code and making it ready. A few things will need to be extracted. We also will extract key features into Ruby gems, likely before the whole codebase is released. The first thing we will probably open source are things related to our markdown editor and parser.

Ask about any of this, or suggest anything. We're really excited about opening this all up.
