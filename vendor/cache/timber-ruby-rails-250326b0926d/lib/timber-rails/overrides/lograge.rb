# Timber and lograge are not compatible installed together. Using lograge
# with the Timber.io *service* is perfectly fine, but not with the Timber *gem*.
#
# Timber does ship with a {Timber::Config#logrageify!} option that configures
# Timber to behave similarly to Lograge (silencing various logs). Check out
# the aforementioned method or the README for info.
begin
  require "lograge"

  module Lograge
    module_function

    def setup(app)
      return true
    end
  end
rescue Exception
end