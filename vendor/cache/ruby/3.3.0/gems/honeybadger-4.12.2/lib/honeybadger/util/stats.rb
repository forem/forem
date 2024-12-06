module Honeybadger
  module Util
    class Stats
      HAS_MEM = File.exist?("/proc/meminfo")
      HAS_LOAD = File.exist?("/proc/loadavg")

      class << self
        def all
          { :mem => memory, :load => load }
        end

        # From https://github.com/bloopletech/webstats/blob/master/server/data_providers/mem_info.rb
        def memory
          out = {}
          if HAS_MEM && (meminfo = run_meminfo)
            out[:total], out[:free], out[:buffers], out[:cached] = meminfo[0..4].map { |l| l =~ /^.*?\: +(.*?) kB$/; ($1.to_i / 1024.0).to_f }
            out[:free_total] = out[:free] + out[:buffers] + out[:cached]
          end
          out
        end

        # From https://github.com/bloopletech/webstats/blob/master/server/data_providers/cpu_info.rb
        def load
          out = {}
          if HAS_LOAD && (loadavg = run_loadavg)
            out[:one], out[:five], out[:fifteen] = loadavg.split(' ', 4).map(&:to_f)
          end
          out
        end

        private

        def run_meminfo
          run { IO.readlines("/proc/meminfo") }
        end

        def run_loadavg
          run { IO.read("/proc/loadavg") }
        end

        def run
          yield
        rescue Errno::ENFILE
          # Catch issues like 'Too many open files in system'
          nil
        end
      end
    end
  end
end
