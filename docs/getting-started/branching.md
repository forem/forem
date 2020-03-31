---
title: Creating a Branch
---

# Creating a feature/bug branch

When you are working on a bug, feature, or improvement, you will need to create
a branch.

Branches names should be prefixed with your own GitHub username. If they have an
associated issue, the issue ID should be added as a suffix. For example:

```shell
git checkout -b USERNAME/that-new-feature-1234
```

or

```shell
git checkout -b USERNAME/fixing-that-bug-1234
```

where `USERNAME` should be replaced by your username on GitHub and `1234` is the
ID of the issue tied to your pull request. If there is no related issue, you can
leave the number out.
