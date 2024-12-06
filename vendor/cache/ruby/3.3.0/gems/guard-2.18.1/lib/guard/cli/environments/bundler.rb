require "guard/ui"

module Guard
  module Cli
    module Environments
      class Bundler
        def verify
          return unless File.exist?("Gemfile")
          return if ENV["BUNDLE_GEMFILE"] || ENV["RUBYGEMS_GEMDEPS"]
          UI.info <<EOF

Guard here! It looks like your project has a Gemfile, yet you are running
`guard` outside of Bundler. If this is your intent, feel free to ignore this
message. Otherwise, consider using `bundle exec guard` to ensure your
dependencies are loaded correctly.
(You can run `guard` with --no-bundler-warning to get rid of this message.)
EOF
        end
      end
    end
  end
end
