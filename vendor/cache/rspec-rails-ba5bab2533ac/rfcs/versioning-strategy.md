# RFC: RSpec Rails new versioning strategy

Hi Folks,

This RFC captures a proposal for RSpec Rails' new versioning strategy. Specifically, this represents two things:
* A change in representation of what we use SemVer for, in RSpec Rails
* A departure from RSpec Rails having the same versioning as RSpec's other gems (-core, -mocks, -expectations, and, internally, -support).

## Need

Currently, the RSpec Rails [build matrix](https://travis-ci.org/rspec/rspec-rails)
has 63 entries. This permutes rubies since 1.8.7 and Rails versions since 3.0.
As of right now the full build takes over an hour to run, and this makes cycling
for PRs and quick iterative development very difficult.

RSpec Rails's code itself also is damaged by this. Everything from the Gemfile
setup[1](https://github.com/rspec/rspec-rails/blob/1d2935861c89246236b46f77de753cda5ea67d61/Gemfile)
[2](https://github.com/rspec/rspec-rails/blob/1d2935861c89246236b46f77de753cda5ea67d61/Gemfile-rails-dependencies)
[3](https://github.com/rspec/rspec-rails/blob/1d2935861c89246236b46f77de753cda5ea67d61/Gemfile-rspec-dependencies),
to the [library code](https://github.com/rspec/rspec-rails/blob/1d2935861c89246236b46f77de753cda5ea67d61/lib/rspec/rails/configuration.rb#L128-L143),
to the [test setup](https://github.com/rspec/rspec-rails/blob/1d2935861c89246236b46f77de753cda5ea67d61/Rakefile#L29-L53),
to the [tests themselves](https://github.com/rspec/rspec-rails/blob/1d2935861c89246236b46f77de753cda5ea67d61/spec/rspec/rails/example/job_example_group_spec.rb)
contain conditional execution based on which Rails version is currently loaded.
This makes ongoing maintenance difficult, as it requires that RSpec Rails'
maintainers be conscious of every Rails version that might be loaded.
Acknowledging that, patches still sometimes break people's suites, due to the
number of permutations of gems that can be loaded.

Our need is therefore best characterised by cost of maintenance. Having to
maintain several versions of Rails and Ruby costs us a lot. It makes our
development slower, and forces us to write against Rails versions that most
people no longer use. I want RSpec Rails development to be fast, and
lightweight, much like it was when I joined the RSpec project.

## Approach

The approach to fix this is an adjustment of versioning strategy. RSpec Rails
will still continue to maintain a SemVer strategy, that is:

* Breaking changes in Majors
* New features in Minors
* Bug Fixes in Patchlevels

For the purposes of this versioning strategy, we consider removing a Rails or
Ruby version to be a breaking change. We consider adding a Ruby or Rails version
to be a Minor, along with normal feature releases.

The intent, however, is to change the cycle of these releases to align with
Rails. Specifically, a Rails release cycle typically looks like:

* Release a Major X.0, (X-2).0 is no longer supported, all but the most recent
  (X--1) series are unsupported, introduces deprecation warnings for many
  features
* Release a Minor X.1, deprecation warnings from X.0 are now errors
* Release a Minor X.2, new features are added, some further deprecation warnings
  from X.1 may now be broken.

As such, RSpec Rails's new versioning strategy will be:

* Release a major with any Rails Major, removing support for any newly
  unsupported versions of Rails, and adding support for the new major.
* Release a minor with any Rails Minor, adding support for the new features
  * Additionally, release minors for any new RSpec features
*  Release patchlevels frequently, as bugfixes occur.

As to the transition to this strategy: it is my intent to move to this strategy
along with releasing support for Rails 5.2 for RSpec Rails, so relatively soon,
dropping support for anything below Rails 4.2, and any Rubies below 2.2. This
means that RSpec Rails 4.0.0 will be released within a handful of months from
this RFC being accepted.

I do expect this to mean that the major version of RSpec Rails will increment
relatively quickly with comparison to the rest of RSpec. I do not think that is
necessarily a bad thing, it does not mean that the library is unstable as such,
but rather that we are tracking our dependencies accurately.

Traditionally, RSpec Rails has been versioned at the same version number as
RSpec. This will represent a departure from that. In order to maintain
compatibility, RSpec Rails will continue to support the RSpec 3 series, and will
probably add support for RSpec 4 without breaking changes. To do this, I intend
to move off RSpec Rails using any private APIs from RSpec.

## Benefits

Execution of this strategy will greatly increase our ability to maintain RSpec,
and release against modern Rails versions. While RSpec has been very stable and
essentially continuously expanded Rails version support for the last few years,
this has now become unsustainable and we want to take this tradeoff to best
serve the needs of the community.

## Competition

### Do nothing

If we do this, it will become deeply unsustainable for us to maintain RSpec
Rails in the future. We have too many Rails versions today, and we expect the
rate of Rails releases to increase as time goes on. As such, it is our intent to
start dropping Rails versions inline with Rails, in order to continue to improve
the RSpec Rails gem.

### Keep inline versioning with RSpec

RSpec has a materially different versioning need to Rails. Specifically, RSpec
as of today is a mostly entirely stable library. It's development needs are
largely as feature proposals occur, or as bugs are found. RSpec has no external
forces pushing versioning pressure on it (other than say, ruby and bundler,
which are themselves, relatively stable). This is not true of RSpec Rails, which
is popular, and there is a general expectation that RSpec will work with Rails
applications, as of right now, we typically lag behind a Rails release by weeks
when a Rails version gets released.

## Conclusions

It is my intent to ship this change relatively soon, inline with Rails 5.2
support in the next few months. I really do think this represents the best
future tradeoff for RSpec. If you strongly believe that dropping support for
Rails versions lower than 4.2 will affect your needs, please do let us know so
that we can consider the full weight of your use case.
