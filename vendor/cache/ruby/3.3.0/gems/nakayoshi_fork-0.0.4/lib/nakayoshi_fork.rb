require "nakayoshi_fork/version"

module NakayoshiFork
  module Behavior
    def fork(nakayoshi: true, cow_friendly: true, &b)
      if nakayoshi && cow_friendly
        h = {}
        4.times{ # maximum 4 times
          GC.stat(h)
          live_slots = h[:heap_live_slots] || h[:heap_live_slot]
          old_objects = h[:old_objects] || h[:old_object]
          remwb_unprotects = h[:remembered_wb_unprotected_objects] || h[:remembered_shady_object]
          young_objects = live_slots - old_objects - remwb_unprotects

          break if young_objects < live_slots / 10

          disabled = GC.enable
          GC.start(full_mark: false)
          GC.disable if disabled
        }
      end

      super(&b)
    end if GC.method(:start).arity != 0
  end
end

class Object
  prepend NakayoshiFork::Behavior
end
