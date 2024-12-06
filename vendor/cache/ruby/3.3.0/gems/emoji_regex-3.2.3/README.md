# Ruby Emoji Regex 💎

[![Gem Version](https://badge.fury.io/rb/emoji_regex.svg)](https://rubygems.org/gems/emoji_regex) [![Node & Ruby CI](https://github.com/ticky/ruby-emoji-regex/workflows/Node%20&%20Ruby%20CI/badge.svg)](https://github.com/ticky/ruby-emoji-regex/actions?query=workflow%3A%22Node+%26+Ruby+CI%22)

A set of Ruby regular expressions for matching Unicode Emoji symbols.

## Background

This is based upon the fantastic work from [Mathias Bynens'](https://mathiasbynens.be/) [`emoji-regex`](https://github.com/mathiasbynens/emoji-regex) Javascript package. `emoji-regex` is cleverly assembled based upon data from the Unicode Consortium.

The regular expressions provided herein are derived from that pacakge.

## Installation

```shell
gem install emoji_regex
```

## Usage

`emoji_regex` provides these regular expressions:

* `EmojiRegex::RGIEmoji` is the regex you most likely want. It matches all emoji recommended for general interchange, as defined by [the Unicode standard's `RGI_Emoji` property](https://unicode.org/reports/tr51/#def_rgi_set). In a future version, this regular expression will be renamed to `EmojiRegex::Regex` and all other regexes removed.

* `EmojiRegex::Regex` is deprecated, and will be replaced with `RGIEmoji` in a future major version. It matches emoji which present as emoji by default, and those which present as emoji when combined with `U+FE0F VARIATION SELECTOR-16`.

* `EmojiRegex::Text` is deprecated, and will be removed in a future major version. It matches emoji which present as text by default (regardless of variation selector), as well as those which present as emoji by default.

### RGI vs Emoji vs Text Presentation

`RGI_Emoji` is a property of emoji symbols, defined in [Unicode Technical Report #51](https://unicode.org/reports/tr51/#def_rgi_set) which marks emoji as being supported by major vendors and therefore expected to be usable generally. In most cases, this is the property you will want when seeking emoji characters.

`Emoji_Presentation` is another such property, [defined in UTR#51](http://unicode.org/reports/tr51/#Emoji_Properties_and_Data_Files) which controls whether symbols are intended to be rendered as emoji by default.

Generally, for emoji which re-use Unicode code points which existed before Emoji itself was introduced to Unicode, `Emoji_Presentation` is `false`. `Emoji_Presentation` may be `true` but `RGI_Emoji` false for characters with non-standard emoji-like representations in certain conditions. Notable cases are the Emoji Keycap Sequences (#️⃣, 1️⃣, 9️⃣, *️⃣, etc.) which are sequences composed of three characters; the base character, an `U+FE0F VARIATION SELECTOR-16`, and finally the `U+20E3 COMBINING ENCLOSING KEYCAP`.

These characters, therefore, are matched to varying degrees of precision by each of the regular expressions included in this package;

- `#` is matched only by `EmojiRegex::Text` as it is considered to be a text part of a possible emoji.
- `#️` is matched by `EmojiRegex::Regex` as well as `EmojiRegex::Text` as it has `Emoji_Presentation` despite not being a generally accepted Emoji or recommended for general interchange.
- `#️⃣` is matched by all three regular expressions, as it is recommended for general interchange.

It's most likely that the regular expression you want is `EmojiRegex::RGIEmoji`! ☺️

### Example

```ruby
require 'emoji_regex'

text = <<TEXT
\u{231A}: ⌚ default Emoji presentation character (Emoji_Presentation)
\u{2194}: ↔ default text presentation character
\u{2194}\u{FE0F}: ↔️ default text presentation character with Emoji variation selector
#: # default text presentation character
#\u{FE0F}: #️ default text presentation character with Emoji variation selector
#\u{FE0F}\u{20E3}: #️⃣ default text presentation character with Emoji variation selector and combining enclosing keycap
\u{1F469}: 👩 Emoji modifier base (Emoji_Modifier_Base)
\u{1F469}\u{1F3FF}: 👩🏿 Emoji modifier base followed by a modifier
TEXT

puts 'EmojiRegex::RGIEmoji'
text.scan EmojiRegex::RGIEmoji do |emoji|
  puts "Matched sequence #{emoji} — code points: #{emoji.length}"
end

puts ''

puts 'EmojiRegex::Regex'
text.scan EmojiRegex::Regex do |emoji|
  puts "Matched sequence #{emoji} — code points: #{emoji.length}"
end

puts ''

puts 'EmojiRegex::Text'
text.scan EmojiRegex::Text do |emoji|
  puts "Matched sequence #{emoji} — code points: #{emoji.length}"
end

```

Console output:

```text
EmojiRegex::RGIEmoji
Matched sequence ⌚ — code points: 1
Matched sequence ⌚ — code points: 1
Matched sequence ↔️ — code points: 2
Matched sequence ↔️ — code points: 2
Matched sequence #️⃣ — code points: 3
Matched sequence #️⃣ — code points: 3
Matched sequence 👩 — code points: 1
Matched sequence 👩 — code points: 1
Matched sequence 👩🏿 — code points: 2
Matched sequence 👩🏿 — code points: 2

EmojiRegex::Regex
Matched sequence ⌚ — code points: 1
Matched sequence ⌚ — code points: 1
Matched sequence ↔️ — code points: 2
Matched sequence ↔️ — code points: 2
Matched sequence #️ — code points: 2
Matched sequence #️ — code points: 2
Matched sequence #️⃣ — code points: 3
Matched sequence #️⃣ — code points: 3
Matched sequence 👩 — code points: 1
Matched sequence 👩 — code points: 1
Matched sequence 👩🏿 — code points: 2
Matched sequence 👩🏿 — code points: 2

EmojiRegex::Text
Matched sequence ⌚ — code points: 1
Matched sequence ⌚ — code points: 1
Matched sequence ↔ — code points: 1
Matched sequence ↔ — code points: 1
Matched sequence ↔️ — code points: 2
Matched sequence ↔️ — code points: 2
Matched sequence # — code points: 1
Matched sequence # — code points: 1
Matched sequence #️ — code points: 2
Matched sequence #️ — code points: 2
Matched sequence #️⃣ — code points: 3
Matched sequence #️⃣ — code points: 3
Matched sequence 👩 — code points: 1
Matched sequence 👩 — code points: 1
Matched sequence 👩🏿 — code points: 2
Matched sequence 👩🏿 — code points: 2
```

_**Note**: The above code and output are verified as part of the spec suite._

## Development

### Requirements

* Ruby
* [Node](https://nodejs.org) (v6 or newer)
* [Yarn](https://yarnpkg.com)

### Initial setup

To install all the Ruby and Javascript dependencies, you can run:

```bash
bin/setup
```

To update the Ruby source files based on the `emoji-regex` library:

```bash
bundle exec rake regenerate
```

### Specs

A spec suite is provided, which can be run as:

```bash
bundle exec rake spec
```

### Versioning Policy

Since [Version 1.0.0](https://github.com/ticky/ruby-emoji-regex/releases/tag/v1.0.0), Ruby Emoji Regex's versions have followed that of the `emoji-regex` package, minus 6 major versions.

Each published version of Ruby Emoji Regex will aim to:
- Include any changes in the provided regex in a version matching that of the `emoji-regex` package, keeping the major and minor versions in step.
- When a patch revision of `emoji-regex` is released, if its changes affect the Ruby port meaningfully, a version will be released with the same or greater patch version.
- If a change is required to correct a bug specific to the Ruby port, the patch number will be incremented.

Likewise, and so far coincidentally, versions of Ruby Emoji Regex follow the Unicode Standard's version, minus 10 major versions. Therefore, version 1 included Unicode 11, version 2 Unicode 12, and 3 Unicode 13.

### Ruby Compatibility Policy

While Ruby Emoji Regex uses features which should function on any Ruby version, it is explicitly intended to work on [MRI Ruby versions which are currently within normal maintenance according to the Ruby team](https://www.ruby-lang.org/en/downloads/branches/).

### Creating a release

1. Update the version in [emoji_regex.gemspec](emoji_regex.gemspec)
1. `rake release`
