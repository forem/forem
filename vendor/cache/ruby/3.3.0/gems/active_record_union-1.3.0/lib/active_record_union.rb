require "active_record_union/version"
require "active_record"
require "active_record_union/active_record/relation/union"

module ActiveRecord
  class Relation
    include Union
  end
end
