---
title: Keeping Your Fork In Sync
---

# Keeping your fork in sync

Now that you have a fork of Forem's source code, there is work you will need to
do to keep it updated.

## Setup your upstream

Inside your Forem directory, add a remote to the official Forem repo:

```shell
git remote add upstream https://github.com/forem/forem.git
```

## Rebasing from upstream

Do this prior to creating each branch for a PR:

Make sure you are on the main branch:

```shell
$ git status
On branch main
Your branch is up-to-date with 'origin/main'.
```

If you aren't on `main`, finish your work and checkout the `main` branch:

```shell
git checkout main
```

Do a pull with rebase against `upstream`:

```shell
git pull --rebase upstream main
```

This will pull down all of the changes to the official `main` branch, without
making an additional commit in your local repo.

(Optional) Force push your updated `main` branch to your GitHub fork

```shell
git push origin main --force
```

This will overwrite the `main` branch of your fork.

## Keeping your branch up to date

Sometimes, your forked branch may get out of date. To get it up to date it,
carry out the following steps:

Rebase from upstream once again:

```shell
git checkout main
git pull --rebase upstream main
```

Checkout your feature branch locally and merge main back into your branch:

```shell
git checkout <feature-branch-name>
git merge main
```

Merge any conflicts in editor if necessary:

```shell
git commit -m "Fix merge conflicts"
```

Push the changes back to your origin feature branch:

```shell
git push origin <feature-branch-name>
```

After you've fetched new commits from upstream, run `./bin/setup`, and it will
install new gems, npm packages, update database, and restart Rails server.

## Additional resources

- [Syncing a fork](https://help.github.com/articles/syncing-a-fork/)
