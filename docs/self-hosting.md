---
title: Self Hosting Forem
---

## Hosting your own Forem instance

The codebase that powers [DEV](https://dev.to) is being
[generalized to empower other communities](https://dev.to/devteam/for-empowering-community-2k6h).
We've just started this journey, but we're excited to see where it takes the
platform.

We aren't quite ready for mainstream adoption of our platform,
[Forem](https://forem.com), but that hasn't stopped some adventurous developers
from standing up new communities.

This page is designed to serve as an FAQ and a checklist of considerations that
are relevant to the goal of eventually hosting your own version of our community
platform.

### Current limitations

- We do not currently have a versioning system that will allow us to share fixes
  and improvements with modified versions of the code.
- We aren't able to ensure support for new instances built from this project,
  yet.

### License restrictions

- Certain aspects of the app are currently hardcoded. For instance: logos,
  certain elements of content, etc. If you were to host the current version of
  the app, you would be inadvertently impersonating the core dev.to project.
- DEV has commercial licenses for certain design components as described in our
  [Design License Info](https://docs.dev.to/design/branding/#design-license-info)
  section. These licenses are specific to the dev.to project, and may not extend
  to self-hosted versions.

### I want to stand up my own entity using the Forem codebase, how can I help?

- You can help us to generalize the code by removing DEV-specific language and
  images and replacing them with environment variables or database tables as
  appropriate.
- You can commit to staying in very close coordination with us as we navigate
  the process together.

The long-term benefits of doing this the right way far outweigh the short-term
gains of spinning something up without consulting us. If you are interested in
getting started with this process, [let us know](https://www.forem.com/)!
