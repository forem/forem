# Solargraph

[![RSpec](https://github.com/castwide/solargraph/actions/workflows/rspec.yml/badge.svg)](https://github.com/castwide/solargraph/actions/workflows/rspec.yml)

## A Ruby Language Server

Solargraph provides a comprehensive suite of tools for Ruby programming: intellisense, diagnostics, inline documentation, and type checking.

## Online Demo

A web-based demonstration of Solargraph's autocomplete is available at https://solargraph.org/demo.

## Installation

Install the gem from the command line:

    gem install solargraph

Or add it to your Gemfile:

    gem 'solargraph', group: :development

## Using Solargraph

Plug-ins and extensions are available for the following editors:

* **Visual Studio Code**
    * Extension: https://marketplace.visualstudio.com/items?itemName=castwide.solargraph
    * GitHub: https://github.com/castwide/vscode-solargraph

* **Sublime Text**
    * Extension: https://packagecontrol.io/packages/LSP
    * GitHub: https://github.com/sublimelsp/LSP
    * Instructions: https://lsp.sublimetext.io/language_servers/#solargraph

* **Vim**
    * GitHub: `LanguageClient-neovim`, https://github.com/autozimu/LanguageClient-neovim
    * GitHub: `coc`, https://github.com/neoclide/coc-solargraph
    * GitHub: `Vim-EasyComplete`, https://github.com/jayli/vim-easycomplete

* **Emacs**
    * GitHub: `eglot.el`, https://github.com/joaotavora/eglot
    * GitHub: `lsp-mode.el`, https://github.com/emacs-lsp/lsp-mode

* **Eclipse**
    * Plugin: https://marketplace.eclipse.org/content/ruby-solargraph
    * GitHub: https://github.com/PyvesB/eclipse-solargraph

### Configuration

Solargraph's behavior can be controlled via optional [configuration](https://solargraph.org/guides/configuration) files. The highest priority file is a `.solargraph.yml` file at the root of the project. If not present, any global configuration at `~/.config/solargraph/config.yml` will apply. The path to the global configuration can be overridden with the `SOLARGRAPH_GLOBAL_CONFIG` environment variable.

### Rails Support
For better Rails support, please consider using [solargraph-rails](https://github.com/iftheshoefritz/solargraph-rails/)

### Gem Support

Solargraph is capable of providing code completion and documentation for gems that have YARD documentation. You can make sure your gems are documented by running `yard gems` from the command line. (YARD is included as one of Solargraph's gem dependencies. The first time you run it might take a while if you have a lot of gems installed).

When editing code, a `require` call that references a gem will pull the documentation into the code maps and include the gem's API in code completion and intellisense.

If your project automatically requires bundled gems (e.g., `require 'bundler/require'`), Solargraph will add all of the Gemfile's default dependencies to the map.

### Type Checking

As of version 0.33.0, Solargraph includes a [type checker](https://github.com/castwide/solargraph/issues/192) that uses a combination of YARD tags and code analysis to report missing type definitions. In strict mode, it performs type inference to determine whether the tags match the types it detects from code.

### Updating Core Documentation

As of version 0.49.0, Solargraph uses [rbs](https://github.com/ruby/rbs) for core and stdlib documentation. The following only applies to prior versions.

The Solargraph gem ships with documentation for Ruby 2.2.2. You can download documentation for other Ruby versions from the command line.

    $ solargraph list-cores      # List the installed documentation versions
    $ solargraph available-cores # List the versions available for download
    $ solargraph download-core   # Install the best match for your Ruby version
    $ solargraph clear           # Reset the documentation cache

### The Documentation Cache

Solargraph uses a cache directory to store documentation for the Ruby core and customized documentation for certain gems. The default location is `~/.solargraph/cache`, e.g., `/home/<username>/.solargraph/cache` on Linux or `C:\Users\<username>\.solargraph` on Windows.

You can change the location of the cache directory with the `SOLARGRAPH_CACHE` environment variable. This can be useful if you want the cache to comply with the XDG Base Directory Specification.

### Solargraph and Bundler

If you're using the language server with a project that uses Bundler, the most comprehensive way to use your bundled gems is to bundle Solargraph.

In the Gemfile:

    gem 'solargraph', group: :development

Run `bundle install` and use `bundle exec yard gems` to generate the documentation. This process documents cached or vendored gems, or even gems that are installed from a local path.

In order to make sure you're using the correct dependencies, you can start the language server with Bundler. In VS Code, there's a `solargraph.useBundler` option. Other clients will vary, but the command you probably want to run is `bundle exec solargraph socket` or `bundle exec solargraph stdio`.

### Rubocop Version

If you have multiple versions of [`rubocop`](https://rubygems.org/gems/rubocop) installed and you would like to choose a version other than the latest to use, this specific version can be configured.

In `.solargraph.yml`:

```yaml
---
reporters:
- rubocop:version=0.61.0  # diagnostics
formatter:
  rubocop:
    version: 0.61.0       # formatting
```

### Integrating Other Editors

The [language server protocol](https://microsoft.github.io/language-server-protocol/specification) is the recommended way for integrating Solargraph into editors and IDEs. Clients can connect using either stdio or TCP. Language client developers should refer to [https://solargraph.org/guides/language-server](https://solargraph.org/guides/language-server).

### More Information

See [https://solargraph.org/guides](https://solargraph.org/guides) for more tips and tutorials about Solargraph.

## Contributing to Solargraph

### Bug Reports and Feature Requests

[GitHub Issues](https://github.com/castwide/solargraph/issues) are the best place to ask questions, report problems, and suggest improvements.

### Development

Code contributions are always appreciated. Feel free to fork the repo and submit pull requests. Check for open issues that could use help. Start new issues to discuss changes that have a major impact on the code or require large time commitments.

### Sponsorship and Donation

Use Patreon to support ongoing development of Solargraph at [https://www.patreon.com/castwide](https://www.patreon.com/castwide).

You can also make one-time donations via PayPal at [https://www.paypal.me/castwide](https://www.paypal.me/castwide).
