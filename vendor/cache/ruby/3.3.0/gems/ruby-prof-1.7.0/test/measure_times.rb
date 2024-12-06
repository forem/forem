# Some classes used in measurement tests
require 'singleton'

module RubyProf
  class C1
    def C1.sleep_wait
      sleep(0.1)
    end

    def C1.busy_wait
      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      while (Process.clock_gettime(Process::CLOCK_MONOTONIC) - starting) < 0.1
      end
    end

    def sleep_wait
      sleep(0.2)
    end

    def busy_wait
      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      while (Process.clock_gettime(Process::CLOCK_MONOTONIC) - starting) < 0.2
      end
    end
  end

  module M1
    def sleep_wait
      sleep(0.3)
    end

    def busy_wait
      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      while (Process.clock_gettime(Process::CLOCK_MONOTONIC) - starting) < 0.3
      end
    end
  end

  class C2
    include M1
    extend M1
  end

  class C3
    include Singleton
    def sleep_wait
      sleep(0.3)
    end

    def busy_wait
      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      while (Process.clock_gettime(Process::CLOCK_MONOTONIC) - starting) < 0.2
      end
    end
  end
end
