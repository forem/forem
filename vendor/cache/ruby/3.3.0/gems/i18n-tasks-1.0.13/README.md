# i18n-tasks [![Build Status][badge-ci]][ci] [![Coverage Status][badge-coverage]][coverage] [![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/glebm/i18n-tasks?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Stand With Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner2-direct.svg)](https://stand-with-ukraine.pp.ua/)

i18n-tasks helps you find and manage missing and unused translations.

<img width="539" height="331" src="https://i.imgur.com/XZBd8l7.png">

This gem analyses code statically for key usages, such as `I18n.t('some.key')`, in order to:

* Report keys that are missing or unused.
* Pre-fill missing keys, optionally from Google Translate or DeepL Pro.
* Remove unused keys.

Thus addressing the two main problems of [i18n gem][i18n-gem] design:

* Missing keys only blow up at runtime.
* Keys no longer in use may accumulate and introduce overhead, without you knowing it.

## Installation

i18n-tasks can be used with any project using the ruby [i18n gem][i18n-gem] (default in Rails).

Add i18n-tasks to the Gemfile:

```ruby
gem 'i18n-tasks', '~> 1.0.13'
```

Copy the default [configuration file](#configuration):

```console
$ cp $(i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/
```

Copy rspec test to test for missing and unused translations as part of the suite (optional):

```console
$ cp $(i18n-tasks gem-path)/templates/rspec/i18n_spec.rb spec/
```

Or for minitest:

```console
$ cp $(i18n-tasks gem-path)/templates/minitest/i18n_test.rb test/
```

## Usage

Run `bundle exec i18n-tasks` to get the list of all the tasks with short descriptions.

### Check health

`i18n-tasks health` checks if any keys are missing or not used,
that interpolations variables are consistent across locales,
and that all the locale files are normalized (auto-formatted):

```console
$ i18n-tasks health
```

### Add missing keys

Add missing keys with placeholders (base value or humanized key):

```console
$ i18n-tasks add-missing
```

This and other tasks accept arguments:

```console
$ i18n-tasks add-missing -v 'TRME %{value}' fr
```

Pass `--help` for more information:

```console
$ i18n-tasks add-missing --help
Usage: i18n-tasks add-missing [options] [locale ...]
    -l, --locales  Comma-separated list of locale(s) to process. Default: all. Special: base.
    -f, --format   Output format: terminal-table, yaml, json, keys, inspect. Default: terminal-table.
    -v, --value    Value. Interpolates: %{value}, %{human_key}, %{value_or_human_key}, %{key}. Default: %{value_or_human_key}.
    -h, --help     Display this help message.
```

### Google Translate missing keys

Translate missing values with Google Translate ([more below on the API key](#google-translation-config)).

```console
$ i18n-tasks translate-missing

# accepts from and locales options:
$ i18n-tasks translate-missing --from=base es fr
```

### DeepL Pro Translate missing keys

Translate missing values with DeepL Pro Translate ([more below on the API key](#deepl-translation-config)).

```console
$ i18n-tasks translate-missing --backend=deepl

# accepts from and locales options:
$ i18n-tasks translate-missing --backend=deepl --from=en fr nl
```

### Yandex Translate missing keys

Translate missing values with Yandex Translate ([more below on the API key](#yandex-translation-config)).

```console
$ i18n-tasks translate-missing --backend=yandex

# accepts from and locales options:
$ i18n-tasks translate-missing --from=en es fr
```

### OpenAI Translate missing keys

Translate missing values with OpenAI ([more below on the API key](#openai-translation-config)).

```console
$ i18n-tasks translate-missing --backend=openai

# accepts from and locales options:
$ i18n-tasks translate-missing --from=en es fr
```

### Find usages

See where the keys are used with `i18n-tasks find`:

```bash
$ i18n-tasks find common.help
$ i18n-tasks find 'auth.*'
$ i18n-tasks find '{number,currency}.format.*'
```

<img width="437" height="129" src="https://i.imgur.com/VxBrSfY.png">

### Remove unused keys

```bash
$ i18n-tasks unused
$ i18n-tasks remove-unused
```

These tasks can infer [dynamic keys](#dynamic-keys) such as `t("category.\#{category.name}")` if you set
`search.strict` to false, or pass `--no-strict` on the command line.

If you want to keep the ordering from the original language file when using remove-unused, pass
`-k` or `--keep-order`.

### Normalize data

Sort the keys:

```console
$ i18n-tasks normalize
```

Sort the keys, and move them to the respective files as defined by [`config.write`](#multiple-locale-files):

```console
$ i18n-tasks normalize -p
```

### Move / rename / merge keys

`i18n-tasks mv <pattern> <target>` is a versatile task to move or delete keys matching the given pattern.

All nodes (leafs or subtrees) matching [`<pattern>`](#key-pattern-syntax) are merged together and moved to `<target>`.

Rename a node (leaf or subtree):

``` console
$ i18n-tasks mv user account
```

Move a node:

``` console
$ i18n-tasks mv user_alerts user.alerts
```

Move the children one level up:

``` console
$ i18n-tasks mv 'alerts.{:}' '\1'
```

Merge-move multiple nodes:

``` console
$ i18n-tasks mv '{user,profile}' account
```

Merge (non-leaf) nodes into parent:

``` console
$ i18n-tasks mv '{pages}.{a,b}' '\1'
```

### Delete keys

Delete the keys by using the `rm` task:

```console
$ i18n-tasks rm 'user.{old_profile,old_title}' another_key
```

### Compose tasks

`i18n-tasks` also provides composable tasks for reading, writing and manipulating locale data. Examples below.

`add-missing` implemented with `missing`, `tree-set-value` and `data-merge`:
```console
$ i18n-tasks missing -f yaml fr | i18n-tasks tree-set-value 'TRME %{value}' | i18n-tasks data-merge
```

`remove-unused` implemented with `unused` and `data-remove` (sans the confirmation):
```console
$ i18n-tasks unused -f yaml | i18n-tasks data-remove
```

Remove all keys from `fr` that do not exist in `en`. Do not change `en`:
```console
$ i18n-tasks missing -t diff -f yaml en | i18n-tasks tree-mv en fr | i18n-tasks data-remove
```

See the full list of tasks with `i18n-tasks --help`.

### Features and limitations

`i18n-tasks` uses an AST scanner for `.rb` and `.html.erb` files, and a regexp-based scanner for other files, such as `.haml`.

#### Relative keys

`i18n-tasks` offers support for relative keys, such as `t '.title'`.

✔ Keys relative to the file path they are used in (see [relative roots configuration](#usage-search)) are supported.

✔ Keys relative to `controller.action_name` in Rails controllers are supported. The closest `def` name is used.

#### Plural keys

✔ Plural keys, such as `key.{one,many,other,...}` are fully supported.

#### Reference keys

✔ Reference keys (keys with `:symbol` values) are fully supported. These keys are copied as-is in
`add/translate-missing`, and can be looked up by reference or value in `find`.

#### `t()` keyword arguments

✔ `scope` keyword argument is fully supported by the AST scanner, and also by the Regexp scanner but only when it is the first argument.

✔ `default` argument can be used to pre-fill locale files (AST scanner only).

#### Dynamic keys

By default, dynamic keys such as `t "cats.#{cat}.name"` are not recognized.
I encourage you to mark these with [i18n-tasks-use hints](#fine-tuning).

Alternatively, you can enable dynamic key inference by setting `search.strict` to `false` in the config. In this case,
all the dynamic parts of the key will be considered used, e.g. `cats.tenderlove.name` would not be reported as unused.
Note that only one section of the key is treated as a wildcard for each string interpolation; i.e. in this example,
`cats.tenderlove.special.name` *will* be reported as unused.

#### I18n.localize

`I18n.localize` is not supported, use [i18n-tasks-use hints](#fine-tuning).
This is because the key generated by `I18n.localize` depends on the type of the object passed in and thus cannot be inferred statically.

## Configuration

Configuration is read from `config/i18n-tasks.yml` or `config/i18n-tasks.yml.erb`.
Inspect the configuration with `i18n-tasks config`.

Install the [default config file][config] with:

```console
$ cp $(i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/
```

Settings are compatible with Rails by default.

### Locales

By default, `base_locale` is set to `en` and `locales` are inferred from the paths to data files.
You can override these in the [config][config].

### Storage

The default data adapter supports YAML and JSON files.

#### Multiple locale files

i18n-tasks can manage multiple translation files and read translations from other gems.
To find out more see the `data` options in the [config][config].
NB: By default, only `%{locale}.yml` files are read, not `namespace.%{locale}.yml`. Make sure to check the config.

For writing to locale files i18n-tasks provides 2 options.

##### Pattern router

Pattern router organizes keys based on a list of key patterns, as in the example below:

```
data:
  router: pattern_router
  # a list of {key pattern => file} routes, matched top to bottom
  write:
    # write models.* and views.* keys to the respective files
    - ['{models,views}.*', 'config/locales/\1.%{locale}.yml']
    # or, write every top-level key namespace to its own file
    - ['{:}.*', 'config/locales/\1.%{locale}.yml']
    # default, sugar for ['*', path]
    - 'config/locales/%{locale}.yml'
```

##### Conservative router

Conservative router keeps the keys where they are found, or infers the path from base locale.
If the key is completely new, conservative router will fall back to pattern router behaviour.
Conservative router is the **default** router.

```
data:
  router: conservative_router
  write:
    - ['devise.*', 'config/locales/devise.%{locale}.yml']
    - 'config/locales/%{locale}.yml'
```

If you want to have i18n-tasks reorganize your existing keys using `data.write`, either set the router to
`pattern_router` as above, or run `i18n-tasks normalize -p` (forcing the use of the pattern router for that run).

##### Key pattern syntax

A special syntax similar to file glob patterns is used throughout i18n-tasks to match translation keys:

| syntax       | description                                               |
|:------------:|:----------------------------------------------------------|
|      `*`     | matches everything                                        |
|      `:`     | matches a single key                                      |
|      `*:`    | matches part of a single key                              |
|   `{a, b.c}` | match any in set, can use `:` and `*`, match is captured  |

Example of usage:

```sh
$ bundle exec i18n-tasks mv "{:}.contents.{*}_body" "\1.attributes.\2.body"

car.contents.name_body ⮕ car.attributes.name.body
car.contents.description_body ⮕ car.attributes.description.body
truck.contents.name_body ⮕ truck.attributes.name.body
truck.contents.description_body ⮕ truck.attributes.description.body
```

#### Custom adapters

If you store data somewhere but in the filesystem, e.g. in the database or mongodb, you can implement a custom adapter.
If you have implemented a custom adapter please share it on [the wiki][wiki].

### Usage search

i18n-tasks uses an AST scanner for `.rb` and `.html.erb` files, and a regexp scanner for all other files.
New scanners can be added easily: please refer to [this example](https://github.com/glebm/i18n-tasks/wiki/A-custom-scanner-example).

See the `search` section in the [config file][config] for all available configuration options.
NB: By default, only the `app/` directory is searched.

### Fine-tuning

Add hints to static analysis with magic comment hints (lines starting with `(#|/) i18n-tasks-use` by default):

```ruby
# i18n-tasks-use t('activerecord.models.user') # let i18n-tasks know the key is used
User.model_name.human
```

You can also explicitly ignore keys appearing in locale files via `ignore*` settings.

If you have helper methods that generate translation keys, such as a `page_title` method that returns `t '.page_title'`,
or a `Spree.t(key)` method that returns `t "spree.#{key}"`, use the built-in `PatternMapper` to map these.

For more complex cases, you can implement a [custom scanner][custom-scanner-docs].

See the [config file][config] to find out more.

<a name="google-translation-config"></a>
### Google Translate

`i18n-tasks translate-missing` requires a Google Translate API key, get it at [Google API Console](https://code.google.com/apis/console).

Where this key is depends on your Google API console:

* Old console: API Access -> Simple API Access -> Key for server apps.
* New console: Nav Menu -> APIs & Services -> Credentials -> Create Credentials -> API Keys -> Restrict Key -> Cloud Translation API

In both cases, you may need to create the key if it doesn't exist.

Put the key in `GOOGLE_TRANSLATE_API_KEY` environment variable or in the config file.

```yaml
# config/i18n-tasks.yml
translation:
  google_translate_api_key: <Google Translate API key>
```

<a name="deepl-translation-config"></a>
### DeepL Pro Translate

`i18n-tasks translate-missing` requires a DeepL Pro API key, get it at [DeepL](https://www.deepl.com/pro).

```yaml
# config/i18n-tasks.yml
translation:
  deepl_api_key: <DeepL Pro API key>
  deepl_host: <optional>
  deepl_version: <optional>
```

<a name="yandex-translation-config"></a>
### Yandex Translate

`i18n-tasks translate-missing` requires a Yandex API key, get it at [Yandex](https://tech.yandex.com/translate).

```yaml
# config/i18n-tasks.yml
translation:
  yandex_api_key: <Yandex API key>
```

<a name="openai-translation-config"></a>
### OpenAI Translate

`i18n-tasks translate-missing` requires a OpenAI API key, get it at [OpenAI](https://openai.com/).

```yaml
# config/i18n-tasks.yml
translation:
  openai_api_key: <OpenAI API key>
```

## Interactive console

`i18n-tasks irb` starts an IRB session in i18n-tasks context. Type `guide` for more information.

## Import / export to a CSV spreadsheet

See [i18n-tasks wiki: CSV import and export tasks](https://github.com/glebm/i18n-tasks/wiki/Custom-CSV-import-and-export-tasks).

## Add new tasks

Tasks that come with the gem are defined in [lib/i18n/tasks/command/commands](lib/i18n/tasks/command/commands).
Custom tasks can be added easily, see the examples [on the wiki](https://github.com/glebm/i18n-tasks/wiki#custom-tasks).

# Development

- Install dependencies using `bundle install`
- Run tests using `bundle exec rspec`
- Install [Overcommit](https://github.com/sds/overcommit) by running `overcommit --install`

## Skip Overcommit-hooks

- `SKIP=RuboCop git commit`
- `OVERCOMMIT_DISABLE=1 git commit`


[MIT license]: /LICENSE.txt
[ci]: https://github.com/glebm/i18n-tasks/actions/workflows/tests.yml
[badge-ci]: https://github.com/glebm/i18n-tasks/actions/workflows/tests.yml/badge.svg
[coverage]: https://codeclimate.com/github/glebm/i18n-tasks
[badge-coverage]: https://api.codeclimate.com/v1/badges/5d173e90ada8df07cedc/test_coverage
[config]: https://github.com/glebm/i18n-tasks/blob/main/templates/config/i18n-tasks.yml
[wiki]: https://github.com/glebm/i18n-tasks/wiki "i18n-tasks wiki"
[i18n-gem]: https://github.com/svenfuchs/i18n "svenfuchs/i18n on Github"
[screenshot-i18n-tasks]: https://i.imgur.com/XZBd8l7.png "i18n-tasks screenshot"
[screenshot-find]: https://i.imgur.com/VxBrSfY.png "i18n-tasks find output screenshot"
[adapter-example]: https://github.com/glebm/i18n-tasks/blob/main/lib/i18n/tasks/data/file_system_base.rb
[custom-scanner-docs]: https://github.com/glebm/i18n-tasks/wiki/A-custom-scanner-example
[overcommit]: https://github.com/sds/overcommit#installation
