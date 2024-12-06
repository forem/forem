require 'ffi'

class GetProcessMem
  class Darwin
    extend FFI::Library
    ffi_lib 'proc'


    class TaskInfo < FFI::Struct
      layout :pti_virtual_size, :uint64,
             :pti_resident_size, :uint64,
             :pti_total_user, :uint64,
             :pti_total_system, :uint64,
             :pti_threads_user, :uint64,
             :pti_threads_system, :uint64,
             :pti_policy, :int32,
             :pti_faults, :int32,
             :pti_pageins, :int32,
             :pti_cow_faults, :int32,
             :pti_messages_sent, :int32,
             :pti_messages_received, :int32,
             :pti_syscalls_mach, :int32,
             :pti_syscalls_unix, :int32,
             :pti_csw, :int32,
             :pti_threadnum, :int32,
             :pti_numrunning, :int32,
             :pti_priority, :int32

    end


    attach_function :proc_pidinfo,
                    [
                      :int, #pid
                      :int, # flavour
                      :uint64, #arg, not needed for this selector
                      TaskInfo.by_ref, #output buffer
                      :int, #size of buffer
                    ],
                    :int


    PROC_PIDTASKINFO = 4 #from sys/proc_info.h

    class << self
      def resident_size(pid)
        get_proc_pidinfo(pid)[:pti_resident_size]
      end

      private

      def get_proc_pidinfo(pid)
        data = TaskInfo.new
        result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, data, TaskInfo.size)
        if result == TaskInfo.size
          data
        else
          raise SystemCallError.new("proc_pidinfo returned #{result}", FFI.errno);
        end
      end
    end
  end
end
