Rails Locale Data Repository
============================

[![Gem Version](https://badge.fury.io/rb/rails-i18n.svg)](http://badge.fury.io/rb/rails-i18n)
[![CI](https://github.com/svenfuchs/rails-i18n/actions/workflows/ci.yml/badge.svg)](https://github.com/svenfuchs/rails-i18n/actions/workflows/ci.yml)

Centralization of locale data collection for Ruby on Rails.

## Gem Installation

Include the gem to your Gemfile:

``` ruby
gem 'rails-i18n', '~> 7.0.0' # For 7.0.0
gem 'rails-i18n', '~> 6.0' # For 6.x
gem 'rails-i18n', '~> 5.1' # For 5.0.x, 5.1.x and 5.2.x
gem 'rails-i18n', '~> 4.0' # For 4.0.x
gem 'rails-i18n', '~> 3.0' # For 3.x
gem 'rails-i18n', github: 'svenfuchs/rails-i18n', branch: 'master' # For 5.x
gem 'rails-i18n', github: 'svenfuchs/rails-i18n', branch: 'rails-4-x' # For 4.x
gem 'rails-i18n', github: 'svenfuchs/rails-i18n', branch: 'rails-3-x' # For 3.x
```

Alternatively, execute the following command:

``` shell
gem install rails-i18n -v '~> 7.0.0' # For 7.0.0
gem install rails-i18n -v '~> 6.0' # For 6.x
gem install rails-i18n -v '~> 5.1' # For  For 5.0.x, 5.1.x and 5.2.x
gem install rails-i18n -v '~> 4.0' # For 4.0.x
gem install rails-i18n -v '~> 3.0' # For 3.x
```

Note that your Ruby on Rails version must be 3.0 or higher in order to install the `rails-i18n` gem. For rails 2.x, install it manually as described in the Manual Installation section below.

## Configuration

### Enabled modules

By default, all `rails-i18n` modules (locales, pluralization, transliteration, ordinals) are enabled.

If you would like to only enable specific modules, you can do so in your Rails configuration:

```ruby
# to enable only pluralization rules, but disable all other features
config.rails_i18n.enabled_modules = [:pluralization]

# to enable pluralization and ordinals
config.rails_i18n.enabled_modules = [:pluralization, :ordinals]
```

The possible module names:

* `:locale`
* `:ordinals`
* `:pluralization`
* `:transliteration`

Setting `enabled_modules` will restrict the gem's loaded features to only the specific types.

### Available locales

`rails-i18n` gem initially loads all available locale files, pluralization and transliteration rules. This default behaviour can be changed. If you specify in `config/environments/*` the locales which have to be loaded via `I18n.available_locales` option:

``` ruby
config.i18n.available_locales = ['es-CO', :de]
```

or

``` ruby
config.i18n.available_locales = :nl
```

## Manual Installation

Download desired locale files found in [rails/locale](http://github.com/svenfuchs/rails-i18n/tree/master/rails/locale/) directory and move them into the `config/locales` directory of your Rails application.

If any translation doesn't suit well to the requirements of your application, edit them or add your own locale files.

For more information, visit [Rails Internationalization (I18n) API](http://guides.rubyonrails.org/i18n.html) on the _RailsGuides._

## Usage on Rails 2.3

Locale data whose structure is compatible with Rails 2.3 are available on the separate branch [rails-2-3](https://github.com/svenfuchs/rails-i18n/tree/rails-2-3).

## Available Locales

**Available locales:**

af, ar, az, be, bg, bn, bs, ca, cs, csb, da, de, de-AT, de-CH, de-DE, dsb, dz, el, el-CY, en, en-AU, en-CA, en-CY, en-GB, en-IE, en-IN, en-NZ, en-TT, en-US, en-ZA, eo, es, es-419, es-AR, es-CL, es-CO, es-CR, es-EC, es-ES, es-MX, es-NI, es-PA, es-PE, es-US, es-VE, et, eu, fa, fi, fr, fr-CA, fr-CH, fr-FR, fur, fy, gl, gsw-CH, he, hi, hi-IN, hr, hsb, hu, id, is, it, it-CH, ja, ka, kk, km, kn, ko, lb, lo, lt, lv, mg, mk, ml, mn, mr-IN, ms, nb, ne, nl, nn, oc, or, pa, pap-AW, pap-CW, pl, pt, pt-BR, rm, ro, ru, sc, scr, sk, sl, sq, sr, st, sv, sv-FI, sv-SE, sw, ta, te, th, tl, tr, tt, ug, uk, ur, uz, vi, wo, zh-CN, zh-HK, zh-TW, zh-YUE

**Complete locales:**

en, en-US, es, es-419, es-AR, es-CL, es-CO, es-CR, es-EC, es-ES, es-MX, es-NI, es-PA, es-PE, es-US, es-VE, fr, fr-CA, fr-CH, fr-FR, gd, ja, pt, pt-BR, ru, sc

**Locales with missing pluralization rules**

af, csb, dsb, fur, gsw-CH, lb, rm, scr, sq, te, tt, ug, uz

**Removed locales:**

cy

The cy locale was removed in commit 84f6c6b9b7a3e50df2b1fb1ccf7add329f7eab4f since unfortunately we could not find a Welsh speaker to support it.
We would welcome contributions to add it back to the project.
The locale is mostly complete for the missing translations please refer to [#1006](https://github.com/svenfuchs/rails-i18n/issues/1006)

**Removed pluralizations:**

ak, am, bh, bm, bo, br, by, cy, dz, ff, ga, gd, guw, gv, ig, ii, iu, jv, kab, kde, kea, ksh, kw, lag, ln, mo, mt, my, naq, nso, root, sah, se, ses, sg, sh, shi, sma, smi, smj, smn, sms, ti, to, tzm, wa, yo, zh

The above pluralization rules were removed because they did not have corresponding locale files.


Currently, most locales are incomplete. Typically they lack the following keys:

- `activerecord.errors.messages.record_invalid`
- `activerecord.errors.messages.restrict_dependent_destroy.has_one`
- `activerecord.errors.messages.restrict_dependent_destroy.has_many`

The following keys should NOT be included:

- `errors.messages.model_invalid`
- `errors.messages.required`

We always welcome your contributions!

## Currency Symbols

Some locales have the symbol of the currency (e.g. `€`) under the key `number.currency.format.unit`,
while others have the code (e.g. `CHF`). The value of the key depends on the widespread adoption of
the unicode currency symbols by fonts.

For example the Turkish Lira sign (`₺`) was recently added in Unicode 6.2 and while most popular
fonts have a glyph, there are still many fonts that will not render the character correctly.

If you want to provide a different value, you can create a custom locale file under
`config/locales/tr.yml` and override the respective key:

``` yaml
tr:
  number:
    currency:
      format:
        unit: TL
```

## How to Contribute

### Quick Contribution

If you are familiar with GitHub operations, then follow the procedures described in the subsequent sections.

If not,

* Save your locale data in a [Gist](http://gist.github.com).
* Open an issue with reference to the Gist you created.

### Fetching the `rails-i18n` Repository

* Get a github account and Git program if you haven't. See [Help.Github](http://help.github.com/) for instructions.
* Fork `svenfuchs/rails-i18n` repository and clone it into your PC.

### Creating or Editing your Locale File

* Have a look in `rails/locale/en.yml`, which should be used as the base of your translation.
* Create or edit your locale file.
  Please pay attention to save your files as UTF-8.

### Testing your Locale File

Before committing and pushing your changes, test the integrity of your locale file.
(You can also run the tests using Docker, see below)

``` shell
bundle exec rake spec
```

Make sure you have included all translations with:

``` shell
bundle exec rake i18n-spec:completeness rails/locale/en.yml rails/locale/YOUR_NEW_LOCALE.yml
```

Make sure it is normalized with:

``` shell
thor locales:normalize LOCALE # or "thor locales:normalize_all"
```

You can list all complete and incomplete locales:

``` shell
thor locales:complete
thor locales:incomplete
```

Also, you can list all available locales:

``` shell
thor locales:list
```

You can list all missing keys:

``` shell
i18n-tasks missing es
```

### Edit README.md

Add your locale name to the list in `README.md` if it isn't there.

### Send pull request

If you are ready, push the repository into the Github and send us a pull request.

We will do the formality check and publish it as quick as we can.

### Add an informative title to your pull request or issue

If your pull request or issue concerns a specific locale - please indicate the relevant locale
in the issue or pull request title in order to facilitate triage.

**Best:**

*Danish: change da.errors.messages.required to "skal udfyldes"*

**Good:**

*Human precision in Swedish locale file is set to 1*

*Update es-PE.yml, the currency unit is incorrect*

**Bad:**

*Changing some string about validation*

### Docker

Build the image:

```
docker build --tag=railsi18n .
```

Run the tests:

```
docker run railsi18n
```

To run the other commands described above:

```
docker run railsi18n bundle exec rake i18n-spec:completeness rails/locale/en.yml rails/locale/YOUR_NEW_LOCALE.yml
```

## See also

* [devise-i18n](https://github.com/tigrish/devise-i18n)
* [will-paginate-i18n](https://github.com/tigrish/will-paginate-i18n)
* [kaminari-i18n](https://github.com/tigrish/kaminari-i18n)
* [i18n-country-translation](https://github.com/onomojo/i18n-country-translations) for translations of country names
* [i18n-timezones](https://github.com/onomojo/i18n-timezones) for translations of Rails time zones
* [i18n-spec](https://github.com/tigrish/i18n-spec) for RSpec matchers to test your locale files
* [iso](https://github.com/tigrish/iso) for the list of valid language/region codes and their translations
* [i18n-tasks](https://github.com/glebm/i18n-tasks)

## License

[MIT](https://github.com/svenfuchs/rails-i18n/blob/master/MIT-LICENSE.txt)

## Contributors

See [https://github.com/svenfuchs/rails-i18n/contributors](https://github.com/svenfuchs/rails-i18n/contributors)

## Special thanks

[Tsutomu Kuroda](https://github.com/kuroda) for untiringly taking care of this repository, issues and pull requests
