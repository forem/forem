<div align="center">
  <br>
  <h1>Forem 🌱</h1>
  <strong>For Empowering Community</strong>
</div>
<br>
<p align="center">
  <a href="https://github.com/forem/forem/actions/workflows/ci.yml">
    <img src="https://github.com/forem/forem/actions/workflows/ci.yml/badge.svg" alt="CI Build Status">
  </a>
  <a href="https://github.com/forem/forem/actions/workflows/cd.yml">
    <img src="https://github.com/forem/forem/actions/workflows/cd.yml/badge.svg" alt="CD Build Status">
  </a>
  <img src="https://img.shields.io/github/commit-activity/w/forem/forem" alt="GitHub commit activity">
  <a href="https://github.com/forem/forem/issues?q=is%3Aissue+is%3Aopen+label%3A%22ready+for+dev%22">
    <img src="https://img.shields.io/github/issues/forem/forem/ready%20for%20dev" alt="GitHub issues ready for dev">
  </a>
  <a href="https://gitpod.io/#https://github.com/forem/forem">
    <img src="https://img.shields.io/badge/setup-automated-blue?logo=gitpod" alt="GitPod badge">
  </a>
</p>

Welcome to the [Forem](https://forem.com) codebase, the platform that powers
[dev.to](https://dev.to). We are so excited to have you. With your help, we can
build out Forem’s usability, scalability, and stability to better serve our
communities.

## What is Forem?

Forem is open source software for building communities. Communities for your
peers, customers, fanbases, families, friends, and any other time and space
where people need to come together to be part of a collective.
[See our announcement post](https://dev.to/devteam/for-empowering-community-2k6h)
for a high-level overview of what Forem is.

[dev.to](https://dev.to) (or just DEV) is hosted by Forem. It is a community of
software developers who write articles, take part in discussions, and build
their professional profiles. We value supportive and constructive dialogue in
the pursuit of great code and career growth for all members. The ecosystem spans
from beginner to advanced developers, and all are welcome to find their place
within our community. ❤️

## Table of Contents

- [What is Forem?](#what-is-forem)
- [Table of Contents](#table-of-contents)
- [Contributing](#contributing)
- [Getting Started](#getting-started)
  - [Installation Documentation](#installation-documentation)
- [Developer Documentation](#developer-documentation)
- [Deployment with Kamal](#deployment-with-kamal)
- [Vulnerability Disclosure](#vulnerability-disclosure)
- [Acknowledgements](#acknowledgements)
- [License](#license)


## Contributing

We welcome pull requests on any issue, regardless of its current status, if it provides a fix or improvement. While we cannot guarantee that every PR will be merged, we value legitimate suggestions and contributions.

**All pull requests should include appropriate tests.** Our current focus is primarily on backend-related regression tests, while frontend changes may require more extensive user review.

We welcome AI-assisted pull requests but will turn away "slop"—all submissions must maintain high standards of code quality and meaningful utility.

🤖 AI Agents should check out `AGENTS.md` for more instructions. For specific IDEs and environments, Forem also synchronizes these rules across `.cursorrules`, `.windsurfrules`, and `.github/copilot-instructions.md`.

Please also check out the [Contributing to Forem guide](https://developers.forem.com/contributing-guide/forem) for more detailed guidelines.

## Getting Started

This section provides a high-level quick start guide. If you're looking for a
more thorough installation guide (for example
[with macOS](https://developers.forem.com/getting-started/installation/mac)),
you'll want to refer to our complete
[Developer Documentation](https://developers.forem.com/).

We run on a [Rails](https://rubyonrails.org/) backend, and we are currently
transitioning to a [Preact](https://preactjs.com/)-first frontend.

**Prerequisites Note**: Forem now utilizes advanced AI embeddings for feed generation. You must ensure your PostgreSQL installation has the `pgvector` extension (version 0.8.0 or higher) installed to support HNSW indexing. This database extension is a **hard requirement** to migrate the database and run the app. 

To install `pgvector`:
- **macOS (Homebrew)**: `brew install pgvector`
- **Linux (Debian/Ubuntu)**: `sudo apt install postgresql-15-pgvector` (adjust `15` to match your installed PostgreSQL version), or compile from source following the [pgvector installation guide](https://github.com/pgvector/pgvector#installation).

However, providing a Gemini API key (`GEMINI_API_KEY`) to actually generate the embeddings is completely optional; if omitted, the app will continue to function normally without semantic recommendations.

A more complete overview of our stack is available in
[our docs](https://developers.forem.com/technical-overview/stack).

To **launch Forem in Gitpod**, please navigate to
[https://gitpod.io/#https://github.com/{your_github_username}/forem](https://gitpod.io/#https://github.com/{your_github_username}/forem).
