# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.1] - 2021-07-20
- Update signature in the call to `Psych.safe_load` (see #11)

## [1.0.0] - 2020-08-31
- Depreciate "whitelist" in favor of "allowlist" by renaming the `whitelist_classes` param to `allowlist_classes`.

If your project uses the `whitelist_classes` param, you will need to upgrade your code as follows:

```ruby
## before
loader = FrontMatterParser::Loader::Yaml.new(whitelist_classes: [Time])

## after
loader = FrontMatterParser::Loader::Yaml.new(allowlist_classes: [Time])
```

## [0.2.1] - 2019-06-06
### Fixed
- Do not add `bin` development executables to generated gem.

## [0.2.0] - 2018-06-11
### Added
- Allow whitelisting classes in YAML loader.

## [0.1.1] - 2017-07-19
### Fixed
- Don't be greedy with front matter end delimiters.
