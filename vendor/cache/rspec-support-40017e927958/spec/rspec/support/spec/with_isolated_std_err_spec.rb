require 'rspec/support/spec'

RSpec.describe 'isolating a spec from the stderr splitter' do
  include RSpec::Support::WithIsolatedStdErr

  it 'allows a spec to output a warning' do
    with_isolated_stderr do
      $stderr.puts "Imma gonna warn you"
    end
  end

  it 'resets $stderr to its original value even if an error is raised' do
    orig_stderr = $stderr

    expect {
      with_isolated_stderr { raise "boom" }
    }.to raise_error("boom")

    expect($stderr).to be(orig_stderr)
  end
end
