# ERB Lint [![Build Status](https://travis-ci.org/Shopify/erb-lint.svg?branch=master)](https://travis-ci.org/Shopify/erb-lint)

`erb-lint` is a tool to help lint your ERB or HTML files using the included linters or by writing your own.

## Requirements

* Ruby 2.3.0+
 - This is due to use of the safe navigation operator (`&.`)
 - This is also due to the use of the tilde-heredoc `<<~` syntax in some tests.

## Installation

```bash
gem install erb_lint
```

...or add the following to your `Gemfile` and run `bundle install`:

```ruby
gem 'erb_lint', require: false
```

## Configuration

Create a `.erb-lint.yml` file in your project, with the following structure:

```yaml
---
EnableDefaultLinters: true
linters:
  ErbSafety:
    enabled: true
    better_html_config: .better-html.yml
  Rubocop:
    enabled: true
    rubocop_config:
      inherit_from:
        - .rubocop.yml
```

See below for linter-specific configuration options.

## Usage

This gem provides a command-line interface which can be run like so:

1. Run `erblint [options]` if the gem is installed standalone.
2. Run `bundle exec erblint [options]` if the gem is installed as a Gemfile dependency for your app.

For example, `erblint --lint-all --enable-all-linters` will run all available
linters on all ERB files in the current directory or its descendants (`**/*.html{+*,}.erb`).

If you want to change the glob that is used, you can configure it by adding it to your config file as follows:

```yaml
---
glob: "**/*.{html,text,js}{+*,}.erb"
linters:
  ErbSafety:
    enabled: true
    better_html_config: .better-html.yml
  Rubocop:
    enabled: true
    rubocop_config:
      inherit_from:
        - .rubocop.yml
```

## Enable or disable default linters
`EnableDefaultLinters`: enables or disables default linters. [Default linters](#Linters) are enabled by default.

## Linters

| Available Linters                                | Default  | Description |
| ------------------------------------------------ |:--------:|-------------|
| [AllowedScriptType](#AllowedScriptType)          | Yes      | prevents the addition of `<script>` tags that have `type` attributes that are not in a white-list of allowed values |
| ClosingErbTagIndent                              | Yes      |             |
| ExtraNewline                                     | Yes      |             |
| [FinalNewline](#FinalNewline)                    | Yes      | warns about missing newline at the end of a ERB template |
| [NoJavascriptTagHelper](#NoJavascriptTagHelper)  | Yes      | prevents the usage of Rails' `javascript_tag` |
| ParserErrors                                     | Yes      |             |
| [RightTrim](#RightTrim)                          | Yes      | enforces trimming at the right of an ERB tag |
| [SelfClosingTag](#SelfClosingTag)                | Yes      | enforces self closing tag styles for void elements |
| [SpaceAroundErbTag](#SpaceAroundErbTag)          | Yes      | enforces a single space after `<%` and before `%>`|
| SpaceIndentation                                 | Yes      |             |
| SpaceInHtmlTag                                   | Yes      |             |
| TrailingWhitespace                               | Yes      |             |
| [DeprecatedClasses](#DeprecatedClasses)          | No       | warns about deprecated css classes |
| [ErbSafety](#ErbSafety)                          | No       | detects unsafe interpolation of ruby data into various javascript contexts and enforce usage of safe helpers like `.to_json`. |
| [Rubocop](#Rubocop)                              | No       | runs RuboCop rules on ruby statements found in ERB templates |


### DeprecatedClasses

DeprecatedClasses will find all classes used on HTML elements and report any classes that violate the rule set that you provide.

A `rule_set` is specified as a list, each with a set of `deprecated` classes and a corresponding `suggestion` to use as an alternative.

Example configuration:

```yaml
---
linters:
  DeprecatedClasses:
    enabled: true
    exclude:
      - 'app/views/shared/deprecated/**'
    addendum: "See UX wiki for help."
    rule_set:
      - deprecated: ['badge[-_\w]*']
        suggestion: "Use the ui_badge() component instead."
```

You can specify an `addendum` to be added to the end of each violation.
The error message format is: `"Deprecated class ... #{suggestion}"`
or `"Deprecated class ... #{suggestion} #{addendum}"` if an `addendum` is present.

Linter-Specific Option | Description
-----------------------|-----------------------------------------------------------------------------------
`rule_set`             | A list of rules, each with a `deprecated` and `suggestion` option.
`deprecated`           | A list of **regular expressions** which specify the classes deprecated by this rule.
`suggestion`           | A string to be included in the rule's error message. Make this informative and specific to the rule that it is contained in.
`addendum`             | A string to be included at the end of every error message of the rule set. (Optional)

### FinalNewline

Files must have a final newline. This results in better diffs when
adding lines to the file, since SCM systems such as git won't think that you
touched the last line.

You can customize whether or not a final newline exists with the `present`
option.

Example configuration:

```yaml
---
linters:
  FinalNewline:
    enabled: true
```

Linter-Specific Option | Description
-----------------------|---------------------------------------------------------
`present`              | Whether a final newline should be present (default **true**)

### ErbSafety

Runs the checks provided by
[better-html's erb safety test helper](https://github.com/Shopify/better-html#testing-for-valid-html-and-erb).

When using ERB interpolations in javascript contexts, this linter enforces the usage of safe helpers such as `.to_json`.
See [better-html's readme](https://github.com/Shopify/better-html#testing-for-valid-html-and-erb) for more information.

Any ERB statement that does not call a safe helper is deemed unsafe and a violation is shown.

For example:
```erb
Not allowed ❌
<a onclick="alert(<%= some_data %>)">

Allowed ✅
<a onclick="alert(<%= some_data.to_json %>)">
```

```erb
Not allowed ❌
<script>var myData = <%= some_data %>;</script>

Allowed ✅
<script>var myData = <%= some_data.to_json %>;</script>
```

Example configuration:

```yaml
---
linters:
  ErbSafety:
    enabled: true
    better_html_config: .better-html.yml
```

Linter-Specific Option | Description
-----------------------|---------------------------------------------------------
`better_html_config`   | Name of the configuration file to use for `better-html`. Optional. Valid options and their defaults are described [in better-html's readme](https://github.com/Shopify/better-html#configuration).

### Rubocop

Runs RuboCop on all ruby statements found in ERB templates. The RuboCop configuration that `erb-lint` uses can inherit from
the configuration that the rest of your application uses. `erb-lint` can be configured independently however, as it will often
be necessary to disable specific RuboCop rules that do not apply to ERB files.

**Note**: Each ruby statement (between ERB tags `<% ... %>`) is parsed and analyzed independently of each other. Any rule that requires a broader context can trigger false positives (e.g. `Lint/UselessAssignment` will complaint for an assignment even if used in a subsequent ERB tag).

Example configuration:

```yaml
---
linters:
  Rubocop:
    enabled: true
    rubocop_config:
      inherit_from:
        - .rubocop.yml
      Layout/InitialIndentation:
        Enabled: false
      Layout/TrailingEmptyLines:
        Enabled: false
      Layout/TrailingWhitespace:
        Enabled: false
      Naming/FileName:
        Enabled: false
      Style/FrozenStringLiteralComment:
        Enabled: false
      Metrics/LineLength:
        Enabled: false
      Lint/UselessAssignment:
        Enabled: false
      Rails/OutputSafety:
        Enabled: false
```

The cops disabled in the example configuration above provide a good starting point.

Linter-Specific Option | Description
-----------------------|---------------------------------------------------------
`rubocop_config`       | A valid rubocop configuration hash. Mandatory when this cop is enabled. See [rubocop's manual entry on Configuration](http://rubocop.readthedocs.io/en/latest/configuration/)
`only`                 | Only run cops listed in this array instead of all cops.

### RightTrim

Trimming at the right of an ERB tag can be done with either `=%>` or `-%>`, this linter enforces one of these two styles.

Example configuration:

```yaml
---
linters:
  RightTrim:
    enabled: true
    enforced_style: '-'
```

Linter-Specific Option | Description
-----------------------|---------------------------------------------------------
`enforced_style`       | Which style to enforce, can be either `-` or `=`. Optional. Defaults to `-`.

### SpaceAroundErbTag

Enforce a single space after `<%` and before `%>` in the ERB source.
This linter ignores opening ERB tags (`<%`) that are followed by a newline,
and closing ERB tags (`%>`) that are preceded by a newline.


```erb
Bad ❌
<%foo%>
<%=foo-%>

Good ✅
<% foo %>

<%
  foo
%>
```

Example configuration:

```yaml
---
linters:
  SpaceAroundErbTag:
    enabled: true
```

### NoJavascriptTagHelper

This linter prevents the usage of
Rails' [`javascript_tag`](https://apidock.com/rails/ActionView/Helpers/JavaScriptHelper/javascript_tag)
helper in ERB templates.

The html parser used in this gem knows not to look for html tags within certain other tags
like `script`, `style`, and others. The html parser does this to avoid confusing javascript
expressions like `if (1<a || b>1)` for a malformed html tag. Using the `javascript_tag` in
a ERB template prevents the parser from recognizing the change of parsing context and may
fail or produce erroneous output as a result.

```erb
Bad ❌
<%= javascript_tag(content, defer: true) %>
Good ✅
<script defer="true"><%== content %></script>

Bad ❌
<%= javascript_tag do %>
  alert(1)
<% end %>
Good ✅
<script>
  alert(1)
</script>
```

The autocorrection rule adds `//<![CDATA[` and `//]]>` markers to the existing script, as this is the default
behavior for `javascript_tag`. This can be disabled by changing the `correction_style` linter option
from `cdata` to `plain`.

Example configuration:

```yaml
---
linters:
  NoJavascriptTagHelper:
    enabled: true
    correction_style: 'plain'
```

Linter-Specific Option | Description
-----------------------|---------------------------------------------------------
`correction_style`     | When configured with `cdata`, adds CDATA markers. When configured with `plain`, don't add makers. Defaults to `cdata`.

### SelfClosingTag

This linter enforces self closing tag styles for void elements.

The void elements are `area`, `base`, `br`, `col`, `embed`, `hr`, `img`, `input`, `keygen`, `link`, `menuitem`, `meta`, `param`, `source`, `track`, and `wbr`.

If `enforced_style` is set to `always` (XHTML style):

```erb
Bad ❌
<link rel="stylesheet" type="text/css" href="styles.css">
Good ✅
<img src="someimage.png" alt="Some Image" />
```

If `enforced_style` is set to `never` (HTML5 style):
```erb
Bad ❌
<hr />
Good ✅
<meta charset="UTF-8">
```

Example configuration:

```yaml
---
linters:
  SelfClosingTag:
    enabled: true
    enforced_style: 'always'
```

Linter-Specific Option | Description
-----------------------|---------------------------------------------------------
`enforced_style`       |  If we should `always` or `never` expect self closing tags for void elements. Defaults to `never`.

### AllowedScriptType

This linter prevent the addition of `<script>` tags that have `type` attributes that are not in a white-list of allowed values.

It is common practice for web developers to use `<script>` tags with non-executable
`type` attributes, such as `application/json` or `text/html` to pass arbitrary data into an html page.
Despite not being executable, these tags are subject to the same parsing quirks as executable script tags, and
it is therefore more difficult to prevent security issues from creeping in. Consider for instance an application
where it is possible to inject the string `</script><script>` unescaped into a `text/html` tag, the application
would be vulnerable to XSS.

This pattern can easily be replaced by `<div>` tags with `data` attributes that can just as easily be read
from javascript, and have the added benefit of being safer. When `content_tag(:div)` or `tag.div()` is used
to pass arbitrary user data into the html document, it becomes much harder to inadvertently introduce a
security issue.

It may also be desirable to avoid typos in `type` attributes.

```html
Bad ❌
<script type="text/javacsrïpt"></script>
Good ✅
<script type="text/javascript"></script>
```

By default, this linter allows the `type` attribute to be omitted, as the behavior in browsers is to
consider `<script>` to be the same as `<script type="text/javascript">`. When the linter is configured with
`allow_blank: false`, instances of `<script>` tags without a type will be auto-corrected
to `<script type="text/javascript">`.

It may also be desirable to disallow `<script>` tags from appearing anywhere in your application.
For instance, Rails applications can benefit from serving static javascript code from the asset
pipeline, as well as other security benefits.
The `disallow_inline_scripts: true` config option may be used for that purpose.

Example configuration:

```yaml
---
linters:
  AllowedScriptType:
    enabled: true
    allowed_types:
      - 'application/json'
      - 'text/javascript'
      - 'text/html'
    allow_blank: false
    disallow_inline_scripts: false
```

Linter-Specific Option    | Description
--------------------------|---------------------------------------------------------
`allowed_types`           | An array of allowed types. Defaults to `["text/javascript"]`.
`allow_blank`             | True or false, depending on whether or not the `type` attribute may be omitted entirely from a `<script>` tag.
`disallow_inline_scripts` | Do not allow inline `<script>` tags anywhere in ERB templates. Defaults to `false`.

## Custom Linters

`erb-lint` allows you to create custom linters specific to your project. It will load linters from the `.erb-linters` directory in the root of your
repository. See the [linters directory](lib/erb_lint/linters) for examples of how to write linters.

```ruby
# .erb-linters/custom_linter.rb

module ERBLint
  module Linters
    class CustomLinter < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :custom_message, accepts: String
      end
      self.config_schema = ConfigSchema

      def offenses(processed_source)
        errors = []
        unless processed_source.file_content.include?('this file is fine')
          errors << Offense.new(
            self,
            processed_source.to_source_range(0 ... processed_source.file_content.size),
            "This file isn't fine. #{@config.custom_message}"
          )
        end
        errors
      end
    end
  end
end
```

By default, this linter would be disabled. You can enable it by adding an entry to `.erb-lint.yml`:

```yaml
---
linters:
  CustomLinter:
    enabled: true
    custom_message: We suggest you change this file.
```

Test your linter by running `erblint`'s command-line interface:

```bash
bundle exec erblint --enable-linters custom_linter --lint-all
```

Running this on a random project might yield this output:

```
Linting 15 files with 1 linters...

This file isn't fine. We suggest you change this file.
In file: app/views/layouts/application.html.erb:1

Errors were found in ERB files
```

To write a linter that can autocorrect offenses it detects, simply add an
`autocorrect` method that returns a callable. The callable is called with an instance of
[`RuboCop::Cop::Corrector`](http://www.rubydoc.info/github/bbatsov/RuboCop/RuboCop/Cop/Corrector)
as argument, and therefore erb-lint correctors work exactly as RuboCop correctors do.

```ruby
def autocorrect(_processed_source, offense)
  lambda do |corrector|
    corrector.insert_after(offense.source_range, "this file is fine")
  end
end
```

## Output formats

You can change the output format of ERB Lint by specifying formatters with the `-f/--format` option.

### Multiline (default)

```sh
$ erblint
Linting 8 files with 12 linters...

Remove multiple trailing newline at the end of the file.
In file: app/views/users/show.html.erb:95

Remove newline before `%>` to match start of tag.
In file: app/views/subscriptions/index.html.erb:38

2 error(s) were found in ERB files
```

### Compact

```sh
erblint --format compact
Linting 8 files with 12 linters...
app/views/users/show.html.erb:95:0: Remove multiple trailing newline at the end of the file.
app/views/users/_graph.html.erb:27:37: Extra space detected where there should be no space
2 error(s) were found in ERB files
```

## License

This project is released under the [MIT license](LICENSE.txt).
