module Blazer
  class UploadsConnection < ActiveRecord::Base
    self.abstract_class = true

    establish_connection Blazer.settings["uploads"]["url"] if Blazer.uploads?
  end
end
