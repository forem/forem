require 'pathname'
require 'bigdecimal'

# Cribbed from Unicorn Worker Killer, thanks!
class GetProcessMem
  private_class_method def self.number_to_bigdecimal(value)
    BigDecimal(value)
  end

  private def number_to_bigdecimal(value)
    self.class.send(:number_to_bigdecimal, value)
  end

  KB_TO_BYTE = number_to_bigdecimal 1024          # 2**10   = 1024
  MB_TO_BYTE = number_to_bigdecimal 1_048_576     # 1024**2 = 1_048_576
  GB_TO_BYTE = number_to_bigdecimal 1_073_741_824 # 1024**3 = 1_073_741_824
  CONVERSION = { "kb" => KB_TO_BYTE, "mb" => MB_TO_BYTE, "gb" => GB_TO_BYTE }
  ROUND_UP   = number_to_bigdecimal "0.5"
  attr_reader :pid

  RUNS_ON_WINDOWS = Gem.win_platform?

  if RUNS_ON_WINDOWS
    begin
      require 'sys/proctable'
    rescue LoadError => e
      message = "Please add `sys-proctable` to your Gemfile for windows machines\n"
      message << e.message
      raise e, message
    end
    include Sys
  end

  RUNS_ON_DARWIN =  Gem.platforms.detect do |p|
                      p.is_a?(Gem::Platform) && p.os == 'darwin'
                    end

  if RUNS_ON_DARWIN
    begin
      require 'get_process_mem/darwin'
    rescue LoadError => e
      message = "Please add `ffi` to your Gemfile for darwin (macos) machines\n"
      message << e.message
      raise e, message
    end
  end

  def initialize(pid = Process.pid)
    @status_file  = Pathname.new "/proc/#{pid}/status"
    @process_file = Pathname.new "/proc/#{pid}/smaps"
    @pid          = pid
    @linux        = @status_file.exist?
  end

  def linux?
    @linux
  end

  def bytes
    memory =   linux_status_memory if linux?
    memory ||= darwin_memory if RUNS_ON_DARWIN
    memory ||= ps_memory
  end

  def kb(b = bytes)
    (b/KB_TO_BYTE).to_f
  end

  def mb(b = bytes)
    (b/MB_TO_BYTE).to_f
  end

  def gb(b = bytes)
    (b/GB_TO_BYTE).to_f
  end

  def inspect
    b = bytes
    "#<#{self.class}:0x%08x @mb=#{ mb b } @gb=#{ gb b } @kb=#{ kb b } @bytes=#{b}>" % (object_id * 2)
  end

  # linux stores memory info in a file "/proc/#{pid}/status"
  # If it's available it uses less resources than shelling out to ps
  def linux_status_memory(file = @status_file)
    line = file.each_line.detect {|line| line.start_with? 'VmRSS'.freeze }
    return unless line
    return unless (_name, value, unit = line.split(nil)).length == 3
    CONVERSION[unit.downcase!] * value.to_i
  rescue Errno::EACCES, Errno::ENOENT
    0
  end

  # linux stores detailed memory info in a file "/proc/#{pid}/smaps"
  def linux_memory(file = @process_file)
    lines = file.each_line.select {|line| line.match(/^Rss/) }
    return if lines.empty?
    lines.reduce(0) do |sum, line|
      line.match(/(?<value>(\d*\.{0,1}\d+))\s+(?<unit>\w\w)/) do |m|
        value = number_to_bigdecimal(m[:value]) + ROUND_UP
        unit  = m[:unit].downcase
        sum  += CONVERSION[unit] * value
      end
      sum
    end
  rescue Errno::EACCES
    0
  end

  # Pull memory from `ps` command, takes more resources and can freeze
  # in low memory situations
  def ps_memory
    if RUNS_ON_WINDOWS
      size = ProcTable.ps(pid: pid).working_set_size
      number_to_bigdecimal(size)
    else
      mem = `ps -o rss= -p #{pid}`
      KB_TO_BYTE * number_to_bigdecimal(mem == "" ? 0 : mem)
    end
  end

  def darwin_memory
    Darwin.resident_size(pid)
  rescue Errno::EPERM
    nil
  end
end
