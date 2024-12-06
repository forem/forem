module Zip
  class StreamableDirectory < Entry
    def initialize(zipfile, entry, src_path = nil, permission = nil)
      super(zipfile, entry)

      @ftype = :directory
      entry.get_extra_attributes_from_path(src_path) if src_path
      @unix_perms = permission if permission
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
