# This is the (future) public repo for dev.to

Update: We'll be open-sourcing on August 8, 2018!

The purpose of this repo is for feedback and discussion about the platform. This repo will evolve to host our codebase once it is ready. We want [dev.to](https://dev.to) to eventually be 90%+ open source.

The codebase is not ready yet, so for now, let's just use this to discuss features and provide feedback.

## Current functionality
Host technical blog posts and helpful articles for developers. Publishing is fairly simple and uses a markdown editor that is fully copy and paste compatible with Jekyll, including [front matter](https://jekyllrb.com/docs/frontmatter/).

## Some features on the roadmap

- Votes (reactions) on posts and enhancements for comments
- Richer markdown experience
- Polish up publishing experience
- Smarter "next article" suggestions, and "related podcasts"
- Other stuff 🤔

## The road to open source

Open sourcing the core codebase will involve just working it to the point where it makes sense. Before then, we will extract some parts as Ruby gems (the site is a Rails app).

The first extraction will likely revolve around our markdown renderer. We want to build some custom features into our markdown editor, but it's a work in progress. The placeholder repo for that project is [Super Markdown](https://github.com/thepracticaldev/super-markdown).

Ask about any of this, or suggest anything. We're really excited about opening this all up.
