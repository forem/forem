require 'rspec/support/spec/shell_out'

RSpec.describe RSpec::Support::ShellOut, :slow do
  include described_class

  it 'shells out and returns stdout and stderr' do
    stdout, stderr, _ = shell_out("ruby", "-e", "$stdout.print 'yes'; $stderr.print 'no'")
    expect(stdout).to eq("yes")
    expect(stderr).to eq("no")
  end

  it 'returns the exit status as the third argument' do
    _, _, good_status = shell_out("ruby", "-e", '3 + 3')
    expect(good_status.exitstatus).to eq(0)

    unless RUBY_VERSION.to_f < 1.9 # except 1.8...
      _, _, bad_status = shell_out("ruby", "-e", 'boom')
      expect(bad_status.exitstatus).to eq(1)
    end
  end

  it 'can shell out to ruby with the current load path' do
    skip "Need to investigate why this is failing -- see " \
         "https://travis-ci.org/rspec/rspec-core/jobs/60327106 and " \
         "https://travis-ci.org/rspec/rspec-support/jobs/60296920 for examples"

    out, err, status = run_ruby_with_current_load_path('puts $LOAD_PATH.sort.join("\n")')
    expect(err).to eq("")
    expect(out).to include(*$LOAD_PATH.first(10))
    expect(status.exitstatus).to eq(0)
  end

  it 'passes along the provided ruby flags' do
    out, err, status = run_ruby_with_current_load_path('puts "version"', '-v')
    expect(out).to include('version', RUBY_DESCRIPTION)
    expect(strip_known_warnings err).to eq('')
    expect(status.exitstatus).to eq(0)
  end

  it 'filters out the annoying output issued by `ruby -w` when the GC ENV vars are set' do
    with_env 'RUBY_GC_HEAP_FREE_SLOTS' => '10001', 'RUBY_GC_MALLOC_LIMIT' => '16777217', 'RUBY_FREE_MIN' => '10001' do
      out, err, status = run_ruby_with_current_load_path('', '-w')
      expect(out).to eq('')
      expect(strip_known_warnings err).to eq('')
      expect(status.exitstatus).to eq(0)
    end
  end
end
