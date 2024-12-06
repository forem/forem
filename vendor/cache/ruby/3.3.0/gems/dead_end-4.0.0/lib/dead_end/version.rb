# frozen_string_literal: true

# Calling `DeadEnd::VERSION` forces an eager load due to
# an `autoload` on the `DeadEnd` constant.
#
# This is used for gemspec access in tests
module UnloadedDeadEnd
  VERSION = "4.0.0"
end
