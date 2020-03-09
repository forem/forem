---
title: Keeping Your Fork In Sync
---

# Keeping your fork in sync

Now that you have a fork of DEV's source code, there is work you will need to do
to keep it updated.

## Setup your upstream

Inside your DEV directory, add a remote to the official DEV repo:

```shell
git remote add upstream https://github.com/thepracticaldev/dev.to.git
```

## Rebasing from upstream

Do this prior to creating each branch for a PR:

Make sure you are on the master branch:

```shell
$ git status
On branch master
Your branch is up-to-date with 'origin/master'.
```

If you aren't on `master`, finish your work and checkout the `master` branch:

```shell
git checkout master
```

Do a pull with rebase against `upstream`:

```shell
git pull --rebase upstream master
```

This will pull down all of the changes to the official `master` branch, without
making an additional commit in your local repo.

(Optional) Force push your updated `master` branch to your GitHub fork

```shell
git push origin master --force
```

This will overwrite the `master` branch of your fork.

## Keeping your branch up to date

Sometimes, your forked branch may get out of date. To get it up to date it,
carry out the following steps:

Rebase from upstream once again:

```shell
git checkout master
git pull --rebase upstream master
```

Checkout your feature branch locally and merge master back into your branch:

```shell
git checkout <feature-branch-name>
git merge master
```

Merge any conflicts in editor if necessary:

```shell
git commit -m "Fix merge conflicts"
```

Push the changes back to your origin feature branch:

```shell
git push origin <feature-branch-name>
```

## Additional resources

- [Syncing a fork](https://help.github.com/articles/syncing-a-fork/)
