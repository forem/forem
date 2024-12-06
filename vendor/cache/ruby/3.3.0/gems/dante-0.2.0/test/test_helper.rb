require 'rubygems'
require 'tempfile'
require 'minitest/autorun'
require 'mocha'
$:.unshift File.expand_path("../../lib")
require 'dante'

## Kernel Extensions
require 'stringio'

module Kernel
  # Redirect standard out, standard error and the buffered logger for sprinkle to StringIO
  # capture_stdout { any_commands; you_want } => "all output from the commands"
  def capture_stdout
    return yield if ENV['DEBUG'] # Skip if debug mode

    out = StringIO.new
    $stdout = out
    $stderr = out
    yield
    return out.string
  ensure
    $stdout = STDOUT
    $stderr = STDERR
  end
end

# Process fixture
class TestingProcess
  attr_reader :tmp_path

  def initialize(name)
    @tmp_path = "/tmp/dante-#{name}.log"
  end # initialize

  def run_a!(data=nil)
    @tmp = File.new(@tmp_path, 'w')
    @tmp.puts("Started")
    @tmp.puts "Data is: #{data}" if data
    @tmp.close
  end # run_a!

  def run_b!(port=9090)
    begin
      @tmp = File.new(@tmp_path, 'w')
      @tmp.print "Started on #{port}!!"
      sleep(100)
    rescue Interrupt
      @tmp.print "Interrupt!!"
      exit
    ensure
      @tmp.print "Closing!!"
      @tmp.close
    end
  end # run_b!

  # For logging test
  def run_c!(port=9091)
    puts "Started on #{port}!!"
    sleep(100)
  rescue Interrupt
    puts "Interrupt!!"
    exit
  ensure
    puts "Closing!!"
  end
end # TestingProcess