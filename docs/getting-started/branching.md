---
title: Creating a Feature Branch
---

# Creating a feature/bug branch

When you are working on a bug, feature, or improvement, you will need to
create a branch.

Generally, it can be helpful to prefix a branch name with `feature` or `bug` to
denote what kind of code a reviewer can expect to find on the branch.

For features or improvement, you should create a branch as follows:

```
git checkout -b feature/that-new-feature
```

For a bug branch, you should do as follows:

```
git checkout -b bug/fixing-that-bug
```
