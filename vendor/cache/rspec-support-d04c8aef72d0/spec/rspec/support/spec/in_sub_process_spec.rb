require 'tempfile'

RSpec.describe 'isolating code to a sub process' do
  it 'isolates the block from the main process' do
    in_sub_process do
      module NotIsolated
      end
      expect(defined? NotIsolated).to eq "constant"
    end
    expect(defined? NotIsolated).to be_nil
  end

  if Process.respond_to?(:fork) && !(RUBY_PLATFORM == 'java' && RUBY_VERSION == '1.8.7')

    it 'returns the result of sub process' do
      expect(in_sub_process { :foo }).to eq(:foo)
    end

    it 'returns a UnmarshableObject if the result of sub process cannot be marshaled' do
      expect(in_sub_process { proc {} }).to be_a(RSpec::Support::InSubProcess::UnmarshableObject)
    end

    it 'captures and reraises errors to the main process' do
      expect {
        in_sub_process { raise "An Internal Error" }
      }.to raise_error "An Internal Error"
    end

    it 'captures and reraises test failures' do
      expect {
        in_sub_process { expect(true).to be false }
      }.to raise_error(/expected false/)
    end

    it 'fails if the sub process generates warnings' do
      expect {
        in_sub_process do
          # Redirect stderr so we don't get "boom" in our test suite output
          $stderr.reopen(Tempfile.new("stderr"))

          warn "boom"
        end
      }.to raise_error(RuntimeError, a_string_including("Warnings", "boom"))
    end

  else

    it 'pends the block' do
      expect { in_sub_process { true } }.to raise_error(/This spec requires forking to work properly/)
    end

  end
end
