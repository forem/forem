require File.expand_path('../test_helper', __FILE__)

describe "dante runner" do

  describe "verify options fails" do
    it "should bubble up exception" do
      runner = Dante::Runner.new('test-process', {key1:"val2"}) {
        raise Exception.new("should not get here!!!")
      }

      runner.verify_options_hook = lambda { |opts|
        raise Exception.new("Look for this exception") if(opts[:key1] != "val1")
      }

      err = assert_raises(Exception) {
        runner.execute
      }

      assert_equal(err.message, "Look for this exception")
    end
  end

  describe "with no daemonize" do
    before do
      @process = TestingProcess.new('a')
      @runner = Dante::Runner.new('test-process') { @process.run_a! }
      @stdout = capture_stdout { @runner.execute }
    end

    it "prints correct stdout" do
      assert_match /Starting test-process/, @stdout
    end

    it "starts successfully when executed" do
      @output = File.read(@process.tmp_path)
      assert_match /Started/, @output
    end
  end # no daemonize

  describe "with daemonize flag" do
    before do
      @process = TestingProcess.new('b')
      @run_options = { :daemonize => true, :pid_path => "/tmp/dante.pid", :port => 8080, :log_path => false }
      @runner = Dante::Runner.new('test-process-2', @run_options) { |opts|
        @process.run_b!(opts[:port]) }
      @stdout = capture_stdout { @runner.execute }
      sleep(1)
    end

    it "can properly handles aborts and starts / stops on INT" do
      refute_equal 0, @pid = `cat /tmp/dante.pid`.to_i
      Process.kill "INT", @pid
      sleep(1) # Wait to complete
      @output = File.read(@process.tmp_path)

      assert_match /Started on 8080!!/, @output
      assert_match /Interrupt!!/, @output
      assert_match /Closing!!/, @output
    end

    it "can properly handles aborts and starts / stops on TERM" do
      refute_equal 0, @pid = `cat /tmp/dante.pid`.to_i
      Process.kill "TERM", @pid
      sleep(1) # Wait to complete
      @output = File.read(@process.tmp_path)

      assert_match /Started on 8080!!/, @output
      assert_match /Closing!!/, @output
      refute_match /Interrupt!!/, @output
    end
  end # daemonize

  describe "with daemonize flag and log file specified" do
    before do
      @logfile = '/tmp/dante-logging.log'
      FileUtils.rm(@logfile) if File.exist?(@logfile)
      @process = TestingProcess.new('c')
      @run_options = { :daemonize => true, :pid_path => "/tmp/dante.pid", :port => 8081, :log_path => @logfile }
      @runner = Dante::Runner.new('test-process-2', @run_options) { |opts|
        @process.run_c!(opts[:port]) }
      @runner.execute
      sleep(1)
    end

    it "can properly handles log to file and aborts on INT" do
      refute_equal 0, @pid = `cat /tmp/dante.pid`.to_i
      Process.kill "INT", @pid
      sleep(1) # Wait to complete
      @output = File.read(@logfile)

      assert_match /Started on 8081!!/, @output
      assert_match /Interrupt!!/, @output
      assert_match /Closing!!/, @output
    end
  end

  describe "with daemonize flag and logging flag enabled, and debug flag disabled" do
    before do
      @logfile = '/tmp/dante-logging.log'
      FileUtils.rm(@logfile) if File.exist?(@logfile)
      @process = TestingProcess.new('c')
      @run_options = { :daemonize => true, :pid_path => "/tmp/dante.pid", :port => 8081, :log_path => @logfile, :debug => false }
      @runner = Dante::Runner.new('test-process-2', @run_options) { |opts|
        @process.run_c!(opts[:port]) }
      @runner.execute
      sleep(1)
    end

    it "can properly handles log to file and aborts on INT" do
      refute_equal 0, @pid = `cat /tmp/dante.pid`.to_i
      Process.kill "INT", @pid
      sleep(1) # Wait to complete
      @output = File.read(@logfile)

      assert_match /Started on 8081!!/, @output
      assert_match /Interrupt received/, @output
      assert_match /Closing!!/, @output
    end
  end


  describe "with execute accepting block" do
    before do
      @process = TestingProcess.new('b')
      @run_options = { :daemonize => true, :pid_path => "/tmp/dante.pid", :port => 8080, :log_path => false }
      @runner = Dante::Runner.new('test-process-2', @run_options)
      @stdout = capture_stdout { @runner.execute { |opts| @process.run_b!(opts[:port]) } }
      sleep(1)
    end

    it "can properly handles aborts and starts / stops on INT" do
      refute_equal 0, @pid = `cat /tmp/dante.pid`.to_i
      Process.kill "INT", @pid
      sleep(1) # Wait to complete
      @output = File.read(@process.tmp_path)

      assert_match /Started on 8080!!/, @output
      assert_match /Interrupt!!/, @output
      assert_match /Closing!!/, @output
    end
  end # execute with block

  describe "with parsing options" do
    before do
      Object.send(:remove_const, 'ARGV'); ARGV = ['-t test_text']
      @process = TestingProcess.new('a')
      @runner = Dante::Runner.new('test-process')
      @runner.with_options do |opts|
        opts.on("-t", "--test TEST", String, "Test this thing") { |test| options[:test] = test }
      end
      @stdout = capture_stdout { @runner.execute { |opts| @process.run_a!(opts[:test]) } }
    end

    it "prints correct stdout" do
      assert_match /Starting test-process/, @stdout
    end

    it "prints correct data" do
      @output = File.read(@process.tmp_path)
      assert_match /test_text/, @output
    end

    it "starts successfully when executed" do
      @output = File.read(@process.tmp_path)
      assert_match /Started/, @output
    end
  end # options parsing

  describe "with help command" do
    before do
      Object.send(:remove_const, 'ARGV'); ARGV = ['--help']
      @process = TestingProcess.new('a')
      @runner = Dante::Runner.new('test-process')
      @runner.description = "Test process banana"
      @runner.expects(:exit).once.returns(true)
      @stdout = capture_stdout { @runner.execute { @process.run_a! } }
    end

    it "prints correct stdout" do
      assert_match /test-process - Test process banana/, @stdout
    end
  end # help
end