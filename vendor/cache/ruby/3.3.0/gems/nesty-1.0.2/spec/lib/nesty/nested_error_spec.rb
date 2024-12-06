describe Nesty::NestedError do
  class TestError < StandardError
    include Nesty::NestedError
  end

  # test when no nested error and message is nil
  # test when no nested error and message is not nil
  # test when one level of nesting and nested error is explicitly set
  # test when one level of nesting and nested error is implicit
  # test when two levels of nesting and nested error are explicitly set
  # test when two levels of nesting and all errors are implicit

  let(:outer_message) {'hello'}
  let(:outer_backtrace) {['x', 'a', 'b']}
  let(:error) do
    begin
      raise TestError.new(outer_message, nested)
    rescue => e
      e.set_backtrace(outer_backtrace)
      e
    end
  end

  describe "nested error" do
    subject { error }

    context "when there is no nested error" do
      let(:nested) {nil}
      let(:outer_backtrace) {['a', 'b']}

      context "when message is nil" do
        let(:outer_message) {nil}
        it {subject.message.should == TestError.name}
        it {subject.backtrace.size.should == 2}
        it {subject.backtrace[0].should == 'a'}
      end

      context "when message is not nil" do
        let(:outer_message) {'hello'}
        it {subject.message.should == 'hello'}
        it {subject.backtrace.size.should == 2}
        it {subject.backtrace[1].should == 'b'}
      end
    end

    context "when there is one level of nested error" do
      let(:nested_message) {'foo'}
      let(:nested_backtrace) {['a', 'b']}
      let(:nested) do
        begin
          raise StandardError.new(nested_message)
        rescue => e
          e.set_backtrace(nested_backtrace)
          e
        end
      end

      context "and nested error is explicitly set" do
        it {subject.message.should == 'hello'}
        it {subject.backtrace.size.should == 3}
        it {subject.backtrace[0].should == 'x'}
        it {subject.backtrace[1].should == "a: #{nested_message} (StandardError)"}
        it {subject.backtrace[2].should == 'b'}
      end

      context "and nested error is implicitly set" do
        let(:error) do
          begin
            begin
              raise nested
            rescue => e
              error = TestError.new(outer_message)
              error.set_backtrace(outer_backtrace)
              raise error
            end
          rescue => ae
            ae
          end
        end

        it {subject.message.should == 'hello'}
        it {subject.backtrace.size.should == 3}
        it {subject.backtrace[0].should == 'x'}
        it {subject.backtrace[1].should == "a: #{nested_message} (StandardError)"}
        it {subject.backtrace[2].should == 'b'}
      end
    end

    context "when there are multiple levels of nested error" do
      let(:outer_message) {'hello'}
      let(:outer_backtrace) {['w', 'x', 'y', 'z', 'a', 'b']}
      let(:nested_message) {'foo'}
      let(:nested_backtrace) {['y', 'z', 'a', 'b']}
      let(:nested_nested_message) {'bar'}
      let(:nested_nested_backtrace) {['a', 'b']}
      let(:nested) do
        begin
          raise TestError.new(nested_message, nested_nested)
        rescue => e
          e.set_backtrace(nested_backtrace)
          e
        end
      end
      let(:nested_nested) do
        begin
          raise StandardError.new(nested_nested_message)
        rescue => e
          e.set_backtrace(nested_nested_backtrace)
          e
        end
      end
      it {subject.message.should == 'hello'}
      it {subject.backtrace.size.should == 6}
      it {subject.backtrace[0].should == 'w'}
      it {subject.backtrace[1].should == 'x'}
      it {subject.backtrace[2].should == "y: #{nested_message} (TestError)"}
      it {subject.backtrace[3].should == 'z'}
      it {subject.backtrace[4].should == "a: #{nested_nested_message} (StandardError)"}
      it {subject.backtrace[5].should == 'b'}
    end
  end
end
