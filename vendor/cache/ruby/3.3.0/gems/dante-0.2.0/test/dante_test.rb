require File.expand_path('../test_helper', __FILE__)

describe "dante module" do
  before do
    @process = TestingProcess.new('a')
  end

  it "can run jobs using #run method" do
    capture_stdout do
      Dante.run('test-process') { @process.run_a! }
    end
    @output = File.read(@process.tmp_path)
    assert_match /Started/, @output
  end

end