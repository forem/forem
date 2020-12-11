RSpec.describe "expect { ... }.to raise_error" do
  it_behaves_like("an RSpec matcher", :valid_value => lambda { raise "boom" },
                                      :invalid_value => lambda { }) do
    let(:matcher) { raise_error Exception }
  end

  it "passes if anything is raised" do
    expect { raise "error" }.to raise_error "error"
  end

  it "issues a warning when used without an error class or message" do
    expect_warning_with_call_site __FILE__, __LINE__+1, /without providing a specific error/
    expect { raise }.to raise_error
  end

  it 'issues a warning that includes the current error when used without an error class or message' do
    expect_warning_with_call_site __FILE__, __LINE__+1, /Actual error raised was #<StandardError: boom>/
    expect { raise StandardError.new, 'boom' }.to raise_error
  end

  it "issues a warning when `nil` is passed for an error class" do
    expect_warning_with_call_site __FILE__, __LINE__+1, /with a `nil`/
    expect { raise }.to raise_error(nil)
  end

  it "issues a warning when `nil` is passed for an error class when negated" do
    expect_warning_with_call_site __FILE__, __LINE__+1, /raise_error\(nil\)/
    expect { '' }.not_to raise_error(nil)
  end

  it "issues a warning that does not include current error when it's not present" do
    expect(::Kernel).to receive(:warn) do |message|
      ex = /Actual error raised was/
      expect(message).not_to match ex
    end

    expect {
      expect { '' }.to(raise_error)
    }.to fail_with("expected Exception but nothing was raised")
  end

  it "raises an exception when configured to do so" do
    begin
      RSpec::Expectations.configuration.on_potential_false_positives = :raise
      expect_no_warnings
      expect { expect { '' }.to raise_error }.to raise_error ArgumentError
    ensure
      RSpec::Expectations.configuration.on_potential_false_positives = :warn
    end
  end

  it "can supresses the warning when configured to do so", :warn_about_potential_false_positives do
    RSpec::Expectations.configuration.warn_about_potential_false_positives = false
    expect_no_warnings
    expect { raise }.to raise_error
  end

  it "can supresses the warning when configured to do so", :warn_about_potential_false_positives do
    RSpec::Expectations.configuration.on_potential_false_positives = :nothing
    expect_no_warnings
    expect { raise }.to raise_error
  end

  it 'does not issue a warning when an exception class is specified (even if it is just `Exception`)' do
    expect_no_warnings
    expect { raise "error" }.to raise_error Exception
  end

  it 'does not issue a warning when a message is specified' do
    expect_no_warnings
    expect { raise "error" }.to raise_error "error"
  end

  it 'does not issue a warning when a block is passed' do
    expect_no_warnings
    expect { raise "error" }.to raise_error { |_| }
  end

  it "passes if an error instance is expected" do
    s = StandardError.new
    expect { raise s }.to raise_error(s)
  end

  it 'passes if an error instance with a non string message is raised' do
    special_error =
      Class.new(StandardError) do
        def initialize(message)
          @message = message
        end

        def message
          self
        end

        def to_s
          @message
        end
      end
    s = special_error.new 'Stringlike'
    expect { raise s }.to raise_error('Stringlike')
  end

  it "fails if a different error instance is thrown from the one that is expected" do
    s = StandardError.new("Error 1")
    to_raise = StandardError.new("Error 2")
    expect do
      expect { raise to_raise }.to raise_error(s)
    end.to fail_with(Regexp.new("expected #{s.inspect}, got #{to_raise.inspect} with backtrace"))
  end

  it "passes if an error class is expected and an instance of that class is thrown" do
    s = StandardError.new :bees

    expect { raise s }.to raise_error(StandardError)
  end

  it "fails if nothing is raised" do
    expect {
      expect {}.to raise_error Exception
    }.to fail_with("expected Exception but nothing was raised")
  end
end

RSpec.describe "raise_exception aliased to raise_error" do
  it "passes if anything is raised" do
    expect { raise "exception" }.to raise_exception "exception"
  end
end

RSpec.describe "expect { ... }.to raise_error {|err| ... }" do
  it "passes if there is an error" do
    ran = false
    expect { non_existent_method }.to raise_error { |_e|
      ran = true
    }
    expect(ran).to be_truthy
  end

  it "passes the error to the block" do
    error = nil
    expect { non_existent_method }.to raise_error { |e|
      error = e
    }
    expect(error).to be_kind_of(NameError)
  end
end

RSpec.describe "expect { ... }.to raise_error do |err| ... end" do
  it "passes the error to the block" do
    error = nil
    expect { non_existent_method }.to raise_error do |e|
      error = e
    end
    expect(error).to be_kind_of(NameError)
  end
end

RSpec.describe "expect { ... }.to(raise_error { |err| ... }) do |err| ... end" do
  it "passes the error only to the block taken directly by #raise_error" do
    error_passed_to_curly = nil
    error_passed_to_do_end = nil

    expect { non_existent_method }.to(raise_error { |e| error_passed_to_curly = e }) do |e|
      error_passed_to_do_end = e
    end

    expect(error_passed_to_curly).to be_kind_of(NameError)
    expect(error_passed_to_do_end).to be_nil
  end
end

# rubocop:disable Style/RedundantException
RSpec.describe "expect { ... }.not_to raise_error" do

  context "with a specific error class" do
    it "issues a warning" do
      expect_warning_with_call_site __FILE__, __LINE__+1, /risks false positives/
      expect { "bees" }.not_to raise_error(RuntimeError)
    end

    it "can supresses the warning when configured to do so", :warn_about_potential_false_positives do
      RSpec::Expectations.configuration.warn_about_potential_false_positives = false
      expect_no_warnings
      expect { "bees" }.not_to raise_error(RuntimeError)
    end
  end

  context "with no specific error class" do
    it "passes if nothing is raised" do
      expect {}.not_to raise_error
    end

    it "fails if anything is raised" do
      expect {
        expect { raise RuntimeError, "example message" }.not_to raise_error
      }.to fail_with(/expected no Exception, got #<RuntimeError: example message>/)
    end

    it 'includes the backtrace of the error that was raised in the error message' do
      expect {
        expect { raise "boom" }.not_to raise_error
      }.to raise_error { |e|
        backtrace_line = "#{File.basename(__FILE__)}:#{__LINE__ - 2}"
        expect(e.message).to include("with backtrace", backtrace_line)
      }
    end

    it 'formats the backtrace using the configured backtrace formatter' do
      allow(RSpec::Matchers.configuration.backtrace_formatter).
        to receive(:format_backtrace).
        and_return("formatted-backtrace")

      expect {
        expect { raise "boom" }.not_to raise_error
      }.to raise_error { |e|
        expect(e.message).to include("with backtrace", "formatted-backtrace")
      }
    end
  end
end

RSpec.describe "expect { ... }.to raise_error(message)" do
  it "passes if RuntimeError is raised with the right message" do
    expect { raise 'blah' }.to raise_error('blah')
  end

  it "passes if RuntimeError is raised with a matching message" do
    expect { raise 'blah' }.to raise_error(/blah/)
  end

  it "passes if any other error is raised with the right message" do
    expect { raise NameError.new('blah') }.to raise_error('blah')
  end

  it "fails if RuntimeError error is raised with the wrong message" do
    expect do
      expect { raise 'blarg' }.to raise_error('blah')
    end.to fail_with(/expected Exception with \"blah\", got #<RuntimeError: blarg>/)
  end

  it "fails if any other error is raised with the wrong message" do
    expect do
      expect { raise NameError.new('blarg') }.to raise_error('blah')
    end.to fail_with(/expected Exception with \"blah\", got #<NameError: blarg>/)
  end

  it 'includes the backtrace of any other error in the failure message' do
    expect {
      expect { raise "boom" }.to raise_error(ArgumentError)
    }.to raise_error { |e|
      backtrace_line = "#{File.basename(__FILE__)}:#{__LINE__ - 2}"
      expect(e.message).to include("with backtrace", backtrace_line)
    }
  end
end

RSpec.describe "expect { ... }.to raise_error.with_message(message)" do
  it "raises an argument error if raise_error itself expects a message" do
    expect {
      expect {}.to raise_error("bees").with_message("sup")
    }.to raise_error.with_message(/`expect \{ \}\.to raise_error\(message\)\.with_message\(message\)` is not valid/)
  end

  it "passes if RuntimeError is raised with the right message" do
    expect { raise 'blah' }.to raise_error.with_message('blah')
  end

  it "passes if RuntimeError is raised with a matching message" do
    expect { raise 'blah' }.to raise_error.with_message(/blah/)
  end

  it "passes if any other error is raised with the right message" do
    expect { raise NameError.new('blah') }.to raise_error.with_message('blah')
  end

  it "fails if RuntimeError error is raised with the wrong message" do
    expect do
      expect { raise 'blarg' }.to raise_error.with_message('blah')
    end.to fail_with(/expected Exception with \"blah\", got #<RuntimeError: blarg>/)
  end

  it "fails if any other error is raised with the wrong message" do
    expect do
      expect { raise NameError.new('blarg') }.to raise_error.with_message('blah')
    end.to fail_with(/expected Exception with \"blah\", got #<NameError: blarg>/)
  end
end

RSpec.describe "expect { ... }.not_to raise_error(message)" do
  it "issues a warning" do
    expect_warning_with_call_site __FILE__, __LINE__+1, /risks false positives/
    expect { raise 'blarg' }.not_to raise_error(/blah/)
  end

  it "can supresses the warning when configured to do so", :warn_about_potential_false_positives do
    RSpec::Expectations.configuration.warn_about_potential_false_positives = false
    expect_no_warnings
    expect { raise 'blarg' }.not_to raise_error(/blah/)
  end
end

RSpec.describe "expect { ... }.to raise_error(NamedError)" do
  it "passes if named error is raised" do
    expect { non_existent_method }.to raise_error(NameError)
  end

  it "fails if nothing is raised" do
    expect {
      expect {}.to raise_error(NameError)
    }.to fail_with(/expected NameError but nothing was raised/)
  end

  it "fails if another error is raised (NameError)" do
    expect {
      expect { raise RuntimeError, "example message" }.to raise_error(NameError)
    }.to fail_with(/expected NameError, got #<RuntimeError: example message>/)
  end

  it "fails if another error is raised (NameError)" do
    expect {
      expect { load "non/existent/file" }.to raise_error(NameError)
    }.to fail_with(/expected NameError, got #<LoadError/)
  end
end

RSpec.describe "expect { ... }.not_to raise_error(NamedError)" do
  it "issues a warning" do
    expect_warning_with_call_site __FILE__, __LINE__+1, /risks false positives/
    expect {}.not_to raise_error(NameError)
  end

  it "can supresses the warning when configured to do so", :warn_about_potential_false_positives do
    RSpec::Expectations.configuration.warn_about_potential_false_positives = false
    expect_no_warnings
    expect {}.not_to raise_error(NameError)
  end
end

RSpec.describe "expect { ... }.to raise_error(NamedError, error_message) with String" do
  it "passes if named error is raised with same message" do
    expect { raise "example message" }.to raise_error(RuntimeError, "example message")
  end

  it "fails if nothing is raised" do
    expect {
      expect {}.to raise_error(RuntimeError, "example message")
    }.to fail_with(/expected RuntimeError with \"example message\" but nothing was raised/)
  end

  it "fails if incorrect error is raised" do
    expect {
      expect { raise RuntimeError, "example message" }.to raise_error(NameError, "example message")
    }.to fail_with(/expected NameError with \"example message\", got #<RuntimeError: example message>/)
  end

  it "fails if correct error is raised with incorrect message" do
    expect {
      expect { raise RuntimeError.new("not the example message") }.to raise_error(RuntimeError, "example message")
    }.to fail_with(/expected RuntimeError with \"example message\", got #<RuntimeError: not the example message/)
  end
end

RSpec.describe "expect { ... }.not_to raise_error(NamedError, error_message) with String" do
  it "issues a warning" do
    expect_warning_with_call_site __FILE__, __LINE__+1, /risks false positives/
    expect {}.not_to raise_error(RuntimeError, "example message")
  end

  it "can supresses the warning when configured to do so", :warn_about_potential_false_positives do
    RSpec::Expectations.configuration.warn_about_potential_false_positives = false
    expect_no_warnings
    expect {}.not_to raise_error(RuntimeError, "example message")
  end
end

RSpec.describe "expect { ... }.to raise_error(NamedError, error_message) with Regexp" do
  it "passes if named error is raised with matching message" do
    expect { raise "example message" }.to raise_error(RuntimeError, /ample mess/)
  end

  it "fails if nothing is raised" do
    expect {
      expect {}.to raise_error(RuntimeError, /ample mess/)
    }.to fail_with(/expected RuntimeError with message matching \/ample mess\/ but nothing was raised/)
  end

  it "fails if incorrect error is raised" do
    expect {
      expect { raise RuntimeError, "example message" }.to raise_error(NameError, /ample mess/)
    }.to fail_with(/expected NameError with message matching \/ample mess\/, got #<RuntimeError: example message>/)
  end

  it "fails if correct error is raised with incorrect message" do
    expect {
      expect { raise RuntimeError.new("not the example message") }.to raise_error(RuntimeError, /less than ample mess/)
    }.to fail_with(/expected RuntimeError with message matching \/less than ample mess\/, got #<RuntimeError: not the example message>/)
  end
end
# rubocop:enable Style/RedundantException

RSpec.describe "expect { ... }.not_to raise_error(NamedError, error_message) with Regexp" do
  it "issues a warning" do
    expect_warning_with_call_site __FILE__, __LINE__+1, /risks false positives/
    expect {}.not_to raise_error(RuntimeError, /ample mess/)
  end

  it "can supresses the warning when configured to do so", :warn_about_potential_false_positives do
    RSpec::Expectations.configuration.warn_about_potential_false_positives = false
    expect_no_warnings
    expect {}.not_to raise_error(RuntimeError, /ample mess/)
  end
end

RSpec.describe "expect { ... }.to raise_error(NamedError, error_message) { |err| ... }" do
  it "yields exception if named error is raised with same message" do
    ran = false

    expect {
      raise "example message"
    }.to raise_error(RuntimeError, "example message") { |err|
      ran = true
      expect(err.class).to eq RuntimeError
      expect(err.message).to eq "example message"
    }

    expect(ran).to be(true)
  end

  it "yielded block fails on it's own right" do
    ran, passed = false, false

    expect {
      expect {
        raise "example message"
      }.to raise_error(RuntimeError, "example message") { |_err|
        ran = true
        expect(5).to eq 4
        passed = true
      }
    }.to fail_with(/expected: 4/m)

    expect(ran).to    be_truthy
    expect(passed).to be_falsey
  end

  it "does NOT yield exception if no error was thrown" do
    ran = false

    expect {
      expect {}.to raise_error(RuntimeError, "example message") { |_err|
        ran = true
      }
    }.to fail_with(/expected RuntimeError with \"example message\" but nothing was raised/)

    expect(ran).to eq false
  end

  it "does not yield exception if error class is not matched" do
    ran = false

    expect {
      expect {
        raise "example message"
      }.to raise_error(SyntaxError, "example message") { |_err|
        ran = true
      }
    }.to fail_with(/expected SyntaxError with \"example message\", got #<RuntimeError: example message>/)

    expect(ran).to eq false
  end

  it "does NOT yield exception if error message is not matched" do
    ran = false

    expect {
      expect {
        raise "example message"
      }.to raise_error(RuntimeError, "different message") { |_err|
        ran = true
      }
    }.to fail_with(/expected RuntimeError with \"different message\", got #<RuntimeError: example message>/)

    expect(ran).to eq false
  end
end

RSpec.describe "expect { ... }.not_to raise_error(NamedError, error_message) { |err| ... }" do
  it "issues a warning" do
    expect_warning_with_call_site __FILE__, __LINE__+1, /risks false positives/
    expect {}.not_to raise_error(RuntimeError, "example message") { |err| }
  end

  it "can supresses the warning when configured to do so", :warn_about_potential_false_positives do
    RSpec::Expectations.configuration.warn_about_potential_false_positives = false
    expect_no_warnings
    expect {}.not_to raise_error(RuntimeError, "example message") { |err| }
  end
end

RSpec.describe "Composing matchers with `raise_error`" do
  matcher :an_attribute do |attr|
    chain :equal_to do |value|
      @expected_value = value
    end

    match do |error|
      return false unless error.respond_to?(attr)
      error.__send__(attr) == @expected_value
    end
  end

  class FooError < StandardError
    def foo; :bar; end
  end

  describe "expect { }.to raise_error(matcher)" do
    it 'passes when the matcher matches the raised error' do
      expect { raise FooError }.to raise_error(an_attribute(:foo).equal_to(:bar))
    end

    it 'passes when the matcher matches the exception message' do
      expect { raise FooError, "food" }.to raise_error(a_string_including("foo"))
    end

    it 'fails with a clear message when the matcher does not match the raised error' do
      expect {
        expect { raise FooError }.to raise_error(an_attribute(:foo).equal_to(3))
      }.to fail_including("expected Exception with an attribute :foo equal to 3, got #<FooError: FooError>")
    end

    it 'fails with a clear message when the matcher does not match the exception message' do
      expect {
        expect { raise FooError, "food" }.to raise_error(a_string_including("bar"))
      }.to fail_including('expected Exception with a string including "bar", got #<FooError: food')
    end

    it 'provides a description' do
      description = raise_error(an_attribute(:foo).equal_to(3)).description
      expect(description).to eq("raise Exception with an attribute :foo equal to 3")
    end
  end

  describe "expect { }.to raise_error(ErrorClass, matcher)" do
    it 'passes when the class and matcher match the raised error' do
      expect { raise FooError, "food" }.to raise_error(FooError, a_string_including("foo"))
    end

    it 'fails with a clear message when the matcher does not match the raised error' do
      expect {
        expect { raise FooError, "food" }.to raise_error(FooError, a_string_including("bar"))
      }.to fail_including('expected FooError with a string including "bar", got #<FooError: food')
    end

    it 'provides a description' do
      description = raise_error(FooError, a_string_including("foo")).description
      expect(description).to eq('raise FooError with a string including "foo"')
    end
  end

  describe "expect { }.to raise_error(ErrorClass).with_message(matcher)" do
    it 'passes when the class and matcher match the raised error' do
      expect { raise FooError, "food" }.to raise_error(FooError).with_message(a_string_including("foo"))
    end

    it 'fails with a clear message when the matcher does not match the raised error' do
      expect {
        expect { raise FooError, "food" }.to raise_error(FooError).with_message(a_string_including("bar"))
      }.to fail_including('expected FooError with a string including "bar", got #<FooError: food')
    end

    it 'provides a description' do
      description = raise_error(FooError).with_message(a_string_including("foo")).description
      expect(description).to eq('raise FooError with a string including "foo"')
    end
  end
end
