RSpec.shared_examples "output_to_stream" do |stream_name, matcher_method, helper_module|
  include helper_module
  extend helper_module

  it_behaves_like "an RSpec block-only matcher" do
    let(:matcher) { output(/fo/).send(matcher_method) }
    def valid_block
      print_to_stream('foo')
    end
    def invalid_block
    end
  end

  define_method :matcher do |*args|
    output(args.first).send(matcher_method)
  end

  it 'is diffable' do
    expect(matcher).to be_diffable
  end

  it 'does not produce warnings when the failure message is accessed first' do
    expect($VERBOSE).to be_truthy
    expect { matcher.failure_message }.not_to output.to_stderr
  end

  context "expect { ... }.to output.#{matcher_method}" do
    it "passes if the block outputs to #{stream_name}" do
      expect { print_to_stream 'foo' }.to matcher
    end

    it "fails if the block does not output to #{stream_name}" do
      expect {
        expect {}.to matcher
      }.to fail_with("expected block to output to #{stream_name}, but did not")
    end
  end

  context "expect { ... }.not_to output.#{matcher_method}" do
    it "passes if the block does not output to #{stream_name}" do
      expect {}.not_to matcher
    end

    it "fails if the block outputs to #{stream_name}" do
      expect {
        expect { print_to_stream 'foo' }.not_to matcher
      }.to fail_with("expected block to not output to #{stream_name}, but output \"foo\"")
    end
  end

  context "expect { ... }.to output('string').#{matcher_method}" do
    it "passes if the block outputs that string to #{stream_name}" do
      expect { print_to_stream 'foo' }.to matcher("foo")
    end

    it "fails if the block does not output to #{stream_name}" do
      expect {
        expect {}.to matcher('foo')
      }.to fail_with("expected block to output \"foo\" to #{stream_name}, but output nothing")
    end

    it "fails if the block outputs a different string to #{stream_name}" do
      expect {
        expect { print_to_stream 'food' }.to matcher('foo')
      }.to fail_with("expected block to output \"foo\" to #{stream_name}, but output \"food\"")
    end
  end

  context "expect { ... }.to_not output('string').#{matcher_method}" do
    it "passes if the block outputs a different string to #{stream_name}" do
      expect { print_to_stream 'food' }.to_not matcher('foo')
    end

    it "passes if the block does not output to #{stream_name}" do
      expect {}.to_not matcher('foo')
    end

    it "fails if the block outputs the same string to #{stream_name}" do
      expect {
        expect { print_to_stream 'foo' }.to_not matcher('foo')
      }.to fail_with("expected block to not output \"foo\" to #{stream_name}, but output \"foo\"")
    end
  end

  context "expect { ... }.to output(/regex/).#{matcher_method}" do
    it "passes if the block outputs a string to #{stream_name} that matches the regex" do
      expect { print_to_stream 'foo' }.to matcher(/foo/)
    end

    it "fails if the block does not output to #{stream_name}" do
      expect {
        expect {}.to matcher(/foo/)
      }.to fail_including("expected block to output /foo/ to #{stream_name}, but output nothing\nDiff")
    end

    it "fails if the block outputs a string to #{stream_name} that does not match" do
      expect {
        expect { print_to_stream 'foo' }.to matcher(/food/)
      }.to fail_including("expected block to output /food/ to #{stream_name}, but output \"foo\"\nDiff")
    end
  end

  context "expect { ... }.to_not output(/regex/).#{matcher_method}" do
    it "passes if the block outputs a string to #{stream_name} that does not match the regex" do
      expect { print_to_stream 'food' }.to_not matcher(/bar/)
    end

    it "passes if the block does not output to #{stream_name}" do
      expect {}.to_not matcher(/foo/)
    end

    it "fails if the block outputs a string to #{stream_name} that matches the regex" do
      expect {
        expect { print_to_stream 'foo' }.to_not matcher(/foo/)
      }.to fail_including("expected block to not output /foo/ to #{stream_name}, but output \"foo\"\nDiff")
    end
  end

  context "expect { ... }.to output(matcher).#{matcher_method}" do
    it "passes if the block outputs a string to #{stream_name} that passes the given matcher" do
      expect { print_to_stream 'foo' }.to matcher(a_string_starting_with("f"))
    end

    it "fails if the block outputs a string to #{stream_name} that does not pass the given matcher" do
      expect {
        expect { print_to_stream 'foo' }.to matcher(a_string_starting_with("b"))
      }.to fail_including("expected block to output a string starting with \"b\" to #{stream_name}, but output \"foo\"\nDiff")
    end
  end

  context "expect { ... }.to_not output(matcher).#{matcher_method}" do
    it "passes if the block does not output a string to #{stream_name} that passes the given matcher" do
      expect { print_to_stream 'foo' }.to_not matcher(a_string_starting_with("b"))
    end

    it "fails if the block outputs a string to #{stream_name} that passes the given matcher" do
      expect {
        expect { print_to_stream 'foo' }.to_not matcher(a_string_starting_with("f"))
      }.to fail_including("expected block to not output a string starting with \"f\" to #{stream_name}, but output \"foo\"\nDiff")
    end
  end
end

module RSpec
  module Matchers
    RSpec.describe "output.to_stderr matcher" do
      include_examples "output_to_stream", :stderr, :to_stderr, Module.new {
        def print_to_stream(msg)
          $stderr.print(msg)
        end
      }
    end

    RSpec.describe "output.to_stdout matcher" do
      include_examples "output_to_stream", :stdout, :to_stdout, Module.new {
        def print_to_stream(msg)
          print(msg)
        end
      }
    end

    RSpec.describe "output.to_stderr_from_any_process matcher" do
      include_examples "output_to_stream", :stderr, :to_stderr_from_any_process, Module.new {
        def print_to_stream(msg)
          if RSpec::Support::OS.windows?
            system("<nul set /p msg=\"#{msg}\" 1>&2")
          else
            system("printf #{msg} 1>&2")
          end
        end
      }
    end

    RSpec.describe "output.to_stdout_from_any_process matcher" do
      include_examples "output_to_stream", :stdout, :to_stdout_from_any_process, Module.new {
        def print_to_stream(msg)
          if RSpec::Support::OS.windows?
            system("<nul set /p msg=#{msg}")
          else
            system("printf #{msg}")
          end
        end
      }
    end

    RSpec.describe "output (without `to_stdout` or `to_stderr`)" do
      it 'raises an error explaining the use is invalid' do
        expect {
          expect { print 'foo' }.to output
        }.to raise_error(/must chain.*to_stdout.*to_stderr/)
      end

      it 'still provides a description (e.g. when used in a one-liner)' do
        expect(output("foo").description).to eq('output "foo" to some stream')
      end
    end
  end
end
