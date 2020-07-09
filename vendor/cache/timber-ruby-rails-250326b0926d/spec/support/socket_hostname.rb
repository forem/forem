require "socket"

# Stub out the hostname for tests only. This can't use a normal stub in the
# test life cycle since our test rails app is loaded once upon initialization.
# In other words, the rails app gets loaded with the server context inserted
# before any tests are run.

class ::Socket
  def self.gethostname
    "computer-name.domain.com"
  end
end