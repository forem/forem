require "unit_spec_helper"

module Rails
  attr_accessor :logger
end

describe Rpush::Logger do
  let(:log) { double(:sync= => true, :level= => nil) }

  before do
    @logger_class = defined?(ActiveSupport::BufferedLogger) ? ActiveSupport::BufferedLogger : ActiveSupport::Logger
    @logger = double(@logger_class.name, info: nil, error: nil, level: 0, :level= => nil, auto_flushing: true, :auto_flushing= => nil)
    allow(@logger_class).to receive(:new).and_return(@logger)
    allow(Rails).to receive_messages(logger: @logger)
    allow(File).to receive_messages(open: log)
    allow(FileUtils).to receive_messages(mkdir_p: nil)
    allow(STDERR).to receive(:puts)
    Rpush.config.foreground = true
    Rpush.config.log_file = 'log/rpush.log'
  end

  it "disables logging if the log file cannot be opened" do
    allow(File).to receive(:open).and_raise(Errno::ENOENT)
    expect(STDERR).to receive(:puts).with(/Logging disabled/)
    Rpush::Logger.new
  end

  it 'creates the log directory' do
    expect(FileUtils).to receive(:mkdir_p).with('/tmp/rails_root/log')
    Rpush::Logger.new
  end

  it "should open the a log file in the Rails log directory" do
    expect(File).to receive(:open).with('/tmp/rails_root/log/rpush.log', 'a')
    Rpush::Logger.new
  end

  it 'sets sync mode on the log descriptor' do
    expect(log).to receive(:sync=).with(true)
    Rpush::Logger.new
  end

  it 'uses the user-defined logger' do
    my_logger = double(:level= => nil)
    Rpush.config.logger = my_logger
    logger = Rpush::Logger.new
    expect(my_logger).to receive(:info)
    Rpush.config.foreground = false
    logger.info('test')
  end

  it 'uses ActiveSupport::BufferedLogger if a user-defined logger is not set' do
    if ActiveSupport.const_defined?('BufferedLogger')
      expect(ActiveSupport::BufferedLogger).to receive(:new).with(log)
      Rpush::Logger.new
    end
  end

  it 'uses ActiveSupport::Logger if BufferedLogger does not exist' do
    stub_const('ActiveSupport::Logger', double)
    allow(ActiveSupport).to receive_messages(const_defined?: false)
    expect(ActiveSupport::Logger).to receive(:new).with(log).and_return(log)
    Rpush::Logger.new
  end

  it 'sets the log level on the logger' do
    stub_const('ActiveSupport::Logger', double)
    allow(ActiveSupport).to receive_messages(const_defined?: false)
    expect(ActiveSupport::Logger).to receive(:new).with(log).and_return(log)
    Rpush.config.log_level = ::Logger::Severity::ERROR
    expect(log).to receive(:level=).with(::Logger::Severity::ERROR)
    Rpush::Logger.new
  end

  it "should print out the msg if running in the foreground" do
    logger = Rpush::Logger.new
    expect(STDOUT).to receive(:puts).with(/hi mom/)
    logger.info("hi mom")
  end

  unless Rpush.jruby? # These tests do not work on JRuby.
    it "should not print out the msg if not running in the foreground" do
      Rpush.config.foreground = false
      logger = Rpush::Logger.new
      expect(STDOUT).not_to receive(:puts).with(/hi mom/)
      logger.info("hi mom")
    end
  end

  it "should prefix log lines with the current time" do
    Rpush.config.foreground = false
    now = Time.now
    allow(Time).to receive(:now).and_return(now)
    logger = Rpush::Logger.new
    expect(@logger).to receive(:info).with(/#{Regexp.escape("[#{now.to_s(:db)}]")}/)
    logger.info("blah")
  end

  it "should prefix error logs with the ERROR label" do
    Rpush.config.foreground = false
    logger = Rpush::Logger.new
    expect(@logger).to receive(:error).with(/#{Regexp.escape("[ERROR]")}/)
    logger.error("eeek")
  end

  it "should prefix warn logs with the WARNING label" do
    Rpush.config.foreground = false
    logger = Rpush::Logger.new
    expect(@logger).to receive(:warn).with(/#{Regexp.escape("[WARNING]")}/)
    logger.warn("eeek")
  end

  it "should handle an Exception instance" do
    Rpush.config.foreground = false
    e = RuntimeError.new("hi mom")
    allow(e).to receive_messages(backtrace: [])
    logger = Rpush::Logger.new
    expect(@logger).to receive(:error).with(/RuntimeError, hi mom/)
    logger.error(e)
  end

  it 'defaults auto_flushing to true if the Rails logger does not respond to auto_flushing' do
    allow(Rails).to receive_messages(logger: double(info: nil, error: nil, level: 0))
    Rpush::Logger.new
    expect(@logger.auto_flushing).to eq(true)
  end
end
