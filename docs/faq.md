## How do I contribute?

Get started with our [`README`](https://github.com/thepracticaldev/dev.to). You can visit this set of docs for more details when you're up and running.

## Actually, I meant how to contribute to these cool docs!

All documentation lives in the [docs folder](https://github.com/thepracticaldev/dev.to/tree/master/docs). Any guides and clarifications are very much welcome.

## I'm getting an error [SOME-ERROR]. Where do I report it?

You can [write a new issue](https://github.com/thepracticaldev/dev.to/issues/new) and let us know what exactly what went wrong. We'll be able to help you debug if we have specific information, the context of how the error happened, and any other information you think would help.

## How do I setup the repo with Windows/Linux/Ubuntu/not macOS?

Unfortunately, the core team develops only macOS right now. We don't have guidelines for other operating systems yet. If you want to get up and running on a different OS, you'll need to have the following installed:

- Ruby
- Ruby on Rails
- [PostgresSQL](/additional-postgres-setup)
- [Yarn](https://yarnpkg.com/en/docs/install)

You can use a guide like [GoRails](https://gorails.com/setup/), but since we have not tried it ourselves we can't fully endorse it. Let us know how it goes, or if you have tips or experience setting all this up! We're open to including guides for other operating systems.

## Error `role "ec2-user" does not exist` on AWS

Setting up PostgresSQL on an AWS EC2 instance (also with AWS Cloud9) and then running `bin/setup` could display this error message.
To solve it, run the following two commands (assuming your PostgresSQL user is named `postgres`):

```
sudo -u postgres createuser -s ec2-user
sudo -u postgres createdb ec2-user
```

Afterwards run `bin/setup` again.
