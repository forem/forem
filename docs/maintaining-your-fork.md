### Maintaining Your Fork

Now that you have a copy of your fork, there is work you will need to do to keep it current.

#### Setup Your Upstream

Inside your dev.to directory, add a remote to the official dev.to repo:

```
$ git remote add upstream https://github.com/thepracticaldev/dev.to.git
```

#### Rebasing from Upstream

Do this prior to every time you create a branch for a PR:

Make sure you are on the master branch

```
$ git status
On branch master
Your branch is up-to-date with 'origin/master'.
```

If your aren't on `master`, resolve outstanding files / commits and checkout the `master` branch

```
$ git checkout master
```

Do a pull with rebase against `upstream`

```
$ git pull --rebase upstream master
```

This will pull down all of the changes to the official `master` branch, without making an additional commit in your local repo.

(Optional) Force push your updated `master` branch to your GitHub fork

```
$ git push origin master --force
```

This will overwrite the `master` branch of your fork.

#### Also see

- [Syncing a fork](https://help.github.com/articles/syncing-a-fork/)
