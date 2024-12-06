# frozen_string_literal: true

$LOAD_PATH.unshift(::File.join(::File.dirname(__FILE__), "lib"))

require "stripe/version"

Gem::Specification.new do |s|
  s.name = "stripe"
  s.version = Stripe::VERSION
  s.required_ruby_version = ">= 2.3.0"
  s.summary = "Ruby bindings for the Stripe API"
  s.description = "Stripe is the easiest way to accept payments online.  " \
                  "See https://stripe.com for details."
  s.author = "Stripe"
  s.email = "support@stripe.com"
  s.homepage = "https://stripe.com/docs/api?lang=ruby"
  s.license = "MIT"

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/stripe/stripe-ruby/issues",
    "changelog_uri" =>
      "https://github.com/stripe/stripe-ruby/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://stripe.com/docs/api?lang=ruby",
    "github_repo" => "ssh://github.com/stripe/stripe-ruby",
    "homepage_uri" => "https://stripe.com/docs/api?lang=ruby",
    "source_code_uri" => "https://github.com/stripe/stripe-ruby",
  }

  ignored = Regexp.union(
    /\A\.editorconfig/,
    /\A\.git/,
    /\A\.rubocop/,
    /\A\.travis.yml/,
    /\A\.vscode/,
    /\Atest/
  )
  s.files = `git ls-files`.split("\n").reject { |f| ignored.match(f) }
  s.executables   = `git ls-files -- bin/*`.split("\n")
                                           .map { |f| ::File.basename(f) }
  s.require_paths = ["lib"]
end
