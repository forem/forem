---
title: Skipping CI for minor changes
---

# Skipping Continuous Integration

It's almost always a good idea to let our [Continuous Integration][ci] tools do
their work, but sometimes it can makes sense to skip CI.

In the case of extremely minor changes, like updating the project README or
fixing a typo in the docs, you might want to skip CI by including `[ci skip]` in
your commit message:

```shell
git commit -m "Fixed a typo in the testing docs [ci skip]"
```

[ci]: /deployment/
