ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# NOTE: We need to ignore this warning early during app startup.
# 1. `parser` is a transitive dependency (`erb_lint` -> `better_html` -> `parser`)
# 2. The warnings are generated while reading the class body, so we need to ignore
#    them *before* the gem's code is read.
# 3. The warning is intentional, it will always occur when the used point release
#    isn't the most recent. Since our update schedule is somewhat influenced by
#    Fedora release cycles right now, this can occur frequently.
require "warning"
Warning.ignore(%r{parser/current})

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
