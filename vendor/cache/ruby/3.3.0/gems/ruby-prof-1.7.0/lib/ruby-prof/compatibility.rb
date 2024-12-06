# encoding: utf-8

# These methods are deprecated and are available for backwards compatability.
module RubyProf
  # call-seq:
  # measure_mode -> measure_mode
  #
  # Returns what ruby-prof is measuring.  Valid values include:
  #
  # * RubyProf::WALL_TIME
  # * RubyProf::PROCESS_TIME
  # * RubyProf::ALLOCATIONS
  # * RubyProf::MEMORY
  def self.measure_mode
    @measure_mode ||= RubyProf::WALL_TIME
  end

  # call-seq:
  # measure_mode=value -> void
  #
  # Specifies what ruby-prof should measure.  Valid values include:
  #
  # * RubyProf::WALL_TIME - Wall time measures the real-world time elapsed between any two moments. If there are other processes concurrently running on the system that use significant CPU or disk time during a profiling run then the reported results will be larger than expected. On Windows, wall time is measured using GetTickCount(), on MacOS by mach_absolute_time, on Linux by clock_gettime and otherwise by gettimeofday.
  # * RubyProf::PROCESS_TIME - Process time measures the time used by a process between any two moments. It is unaffected by other processes concurrently running on the system. Remember with process time that calls to methods like sleep will not be included in profiling results. On Windows, process time is measured using GetProcessTimes and on other platforms by clock_gettime.
  # * RubyProf::ALLOCATIONS - Object allocations measures show how many objects each method in a program allocates. Measurements are done via Ruby's GC.stat api.
  # * RubyProf::MEMORY - Memory measures how much memory each method in a program uses. Measurements are done via Ruby's TracePoint api.
  def self.measure_mode=(value)
    @measure_mode = value
  end

  # Returns the threads that ruby-prof should exclude from profiling
  def self.exclude_threads
    @exclude_threads ||= Array.new
  end

  # Specifies which threads ruby-prof should exclude from profiling
  def self.exclude_threads=(value)
    @exclude_threads = value
  end

  # Starts profiling
  def self.start
    ensure_not_running!
    @profile = Profile.new(:measure_mode => measure_mode, :exclude_threads => exclude_threads)
    @profile.start
  end

  # Pauses profiling
  def self.pause
    ensure_running!
    @profile.pause
  end

  # Is a profile running?
  def self.running?
    if defined?(@profile) and @profile
      @profile.running?
    else
      false
    end
  end

  # Resume profiling
  def self.resume
    ensure_running!
    @profile.resume
  end

  # Stops profiling
  def self.stop
    ensure_running!
    result = @profile.stop
    @profile = nil
    result
  end

  # Profiles a block
  def self.profile(options = {}, &block)
    ensure_not_running!
    options = {:measure_mode => measure_mode, :exclude_threads => exclude_threads }.merge!(options)
    Profile.profile(options, &block)
  end

  # :nodoc:
  def self.start_script(script)
    start
    load script
  end

  private

  def self.ensure_running!
    raise(RuntimeError, "RubyProf.start was not yet called") unless running?
  end

  def self.ensure_not_running!
    raise(RuntimeError, "RubyProf is already running") if running?
  end

  class << self
    extend Gem::Deprecate
    deprecate :measure_mode, "RubyProf::Profile#measure_mode", 2023, 6
    deprecate :measure_mode=, "RubyProf::Profile#measure_mode=", 2023, 6
    deprecate :exclude_threads, "RubyProf::Profile#exclude_threads", 2023, 6
    deprecate :exclude_threads=, "RubyProf::Profile#initialize", 2023, 6
    deprecate :start, "RubyProf::Profile#start", 2023, 6
    deprecate :pause, "RubyProf::Profile#pause", 2023, 6
    deprecate :stop, "RubyProf::Profile#stop", 2023, 6
    deprecate :resume, "RubyProf::Profile#resume", 2023, 6
    deprecate :running?, "RubyProf::Profile#running?", 2023, 6
    deprecate :profile, "RubyProf::Profile.profile", 2023, 6
  end
end
