module RSpec::Matchers::BuiltIn
  RSpec.describe Compound do

    let(:matcher_without_diffable) { include("foo") }

    before do
      allow(RSpec::Matchers.configuration).to receive_messages(:color? => false)
      allow(matcher_without_diffable).to receive(:diffable?).and_raise(NoMethodError)
    end

    shared_examples "making a copy" do |compound_method, copy_method|
      context "when making a copy via `#{copy_method}`" do
        it "uses a copy of the base matchers" do
          matcher_1 = include(3)
          matcher_2 = include(4)
          compound  = matcher_1.__send__(compound_method, matcher_2)
          copy = compound.__send__(copy_method)

          expect(copy).not_to equal(compound)
          expect(copy.matcher_1).not_to equal(matcher_1)
          expect(copy.matcher_1).to be_a(RSpec::Matchers::BuiltIn::Include)
          expect(copy.matcher_1.expected).to eq([3])

          expect(copy.matcher_2).not_to equal(matcher_2)
          expect(copy.matcher_2).to be_a(RSpec::Matchers::BuiltIn::Include)
          expect(copy.matcher_2.expected).to eq([4])
        end

        it "copies custom matchers properly so they can work even though they have singleton behavior" do
          matcher_1 = custom_include(3)
          matcher_2 = custom_include(3)
          compound  = matcher_1.__send__(compound_method, matcher_2)
          copy = compound.__send__(copy_method)

          expect(copy).not_to equal(compound)
          expect(copy.matcher_1).not_to equal(matcher_1)
          expect(copy.matcher_2).not_to equal(matcher_2)

          expect([3]).to copy

          expect { expect([4]).to copy }.to fail_including("expected [4]")
        end
      end
    end

    shared_examples "handles blocks properly" do |meth|
      define_method :combine do |m1, m2|
        m1.__send__(meth, m2)
      end

      context "when used with a block matcher" do
        it 'executes the block only once, regardless of how many matchers are compounded' do
          w, x, y, z = 0, 0, 0, 0
          expect {
            w += 1; x += 2; y += 3; z += 4
          }.to(                 combine(
            change { w }.to(1), combine(
            change { x }.to(2), combine(
            change { y }.to(3),
            change { z }.to(4) ) ) )
          )
        end

        context "does not work when combined with another non-block matcher" do
          example "with the block matcher first" do
            expect {
              x = 0
              expect { x += 2 }.to combine(change { x }.to(2), be_a(Proc))
            }.to fail_with(/supports_block_expectations/)
          end

          example "with the block matcher last" do
            expect {
              x = 0
              expect { x += 2 }.to combine(be_a(Proc), change { x }.to(2))
            }.to fail_with(/supports_block_expectations/)
          end
        end

        context "indicates block expectations are not supported when combined with a custom matcher that does not define `supports_block_expectations?" do
          let(:non_block_matcher) do
            Class.new do
              include ::RSpec::Matchers::Composable
              def matches?(*); true; end
            end.new
          end

          example "with the block matcher first" do
            compound = combine(change {}.to(2), non_block_matcher)
            expect(compound.supports_block_expectations?).to be false
          end

          example "with the block matcher last" do
            compound = combine(non_block_matcher, change {}.to(2))
            expect(compound.supports_block_expectations?).to be false
          end
        end

        context "forwards on any matcher block arguments as needed (such as for `yield_with_args`)" do
          obj = Object.new
          def obj.foo(print_bar=true)
            yield "bar"
            print "printing bar" if print_bar
          end

          example "with the matcher that passes block args first" do
            call_count = 0

            expect { |probe|
              call_count += 1
              obj.foo(&probe)
            }.to combine(yield_with_args(/bar/), output("printing bar").to_stdout)

            expect(call_count).to eq(1)
          end

          example "with the matcher that passes block args last" do
            call_count = 0

            expect { |probe|
              call_count += 1
              obj.foo(&probe)
            }.to combine(output("printing bar").to_stdout, yield_with_args("bar"))

            expect(call_count).to eq(1)
          end

          it "does not support two matchers that both pass arguments to the block" do
            expect {
              expect { |probe|
                obj.foo(false, &probe)
              }.to combine(yield_with_args(/bar/), yield_with_args("bar"))
            }.to raise_error(/cannot be combined/)
          end
        end

        context "when used with `raise_error` (which cannot match against a wrapped block)" do
          it 'does not work when combined with `throw_symbol` (which also cannot match against a wrapped block)' do
            expect {
              expect {}.to combine(raise_error("boom"), throw_symbol(:foo))
            }.to raise_error(/cannot be combined/)
          end

          it 'works when `raise_error` is first' do
            x = 0
            expect {
              x += 2
              raise "boom"
            }.to combine(raise_error("boom"), change { x }.to(2))
          end

          it 'works when `raise_error` is last' do
            x = 0
            expect {
              x += 2
              raise "boom"
            }.to combine(change { x }.to(2), raise_error("boom"))
          end

          context "with nested compound matchers" do
            if meth == :or
              def expect_block
                @x = 0
                expect do
                  print "a"

                  # for or we need `raise "boom"` and one other
                  # to be wrong, so that only the `output("a").to_stdout`
                  # is correct for these specs to cover the needed
                  # behavior.
                  @x += 3
                  raise "bom"
                end
              end
            else
              def expect_block
                @x = 0
                expect do
                  print "a"
                  @x += 2
                  raise "boom"
                end
              end
            end

            it 'works when `raise_error` is first in the first compound matcher' do
              matcher = combine(
                combine(raise_error("boom"), change { @x }.to(2)),
                output("a").to_stdout
              )

              expect_block.to matcher
            end

            it 'works when `raise_error` is last in the first compound matcher' do
              matcher = combine(
                combine(change { @x }.to(2), raise_error("boom")),
                output("a").to_stdout
              )

              expect_block.to matcher
            end

            it 'works when `raise_error` is first in the last compound matcher' do
              matcher = combine(
                change { @x }.to(2),
                combine(raise_error("boom"), output("a").to_stdout)
              )

              expect_block.to matcher
            end

            it 'works when `raise_error` is last in the last compound matcher' do
              matcher = combine(
                change { @x }.to(2),
                combine(output("a").to_stdout, raise_error("boom"))
              )
              expect_block.to matcher
            end
          end
        end
      end

      context "when given a proc and non block matchers" do
        it 'does not treat it as a block expectation expression' do
          p = lambda {}
          expect(p).to combine(be_a(Proc), be(p))

          expect {
            expect(p).to combine(be_a(Integer), eq(3))
          }.to fail_including("expected: 3")
        end
      end
    end

    context "when used as a composable matcher" do
      it 'can pass' do
        expect(["food", "barn"]).to include(
          a_string_starting_with("f").and(ending_with("d")),
          a_string_starting_with("b").and(ending_with("n"))
        )
      end

      it 'can fail' do
        expect {
          expect(["foo", "bar"]).to include(
            a_string_starting_with("f").and(ending_with("d")),
            a_string_starting_with("b").and(ending_with("n"))
          )
        }.to fail_including('expected ["foo", "bar"] to include (a string starting with "f" and ending with "d") and (a string starting with "b" and ending with "n")')
      end

      it 'provides a description' do
        matcher = include(
          a_string_starting_with("f").and(ending_with("d")),
          a_string_starting_with("b").and(ending_with("n"))
        )

        expect(matcher.description).to eq('include (a string starting with "f" and ending with "d") and (a string starting with "b" and ending with "n")')
      end
    end

    describe "expect(...).to matcher.and(other_matcher)" do

      it_behaves_like "an RSpec value matcher", :valid_value => 3, :invalid_value => 4, :disallows_negation => true do
        let(:matcher) { eq(3).and be <= 3 }
      end

      context 'when using boolean AND `&` alias' do
        it_behaves_like "an RSpec value matcher", :valid_value => 3, :invalid_value => 4, :disallows_negation => true do
          let(:matcher) { eq(3) & be_a(Integer) }
        end
      end

      include_examples "making a copy", :and, :dup
      include_examples "making a copy", :and, :clone
      it_behaves_like  "handles blocks properly", :and

      context 'when both matchers pass' do
        it 'passes' do
          expect(3).to eq(3).and be >= 2
        end
      end

      it 'has a description composed of both matcher descriptions' do
        matcher = eq(3).and be >= 2
        expect(3).to matcher
        expect(matcher.description).to eq("eq 3 and be >= 2")
      end

      context 'when only the first matcher fails' do
        it "fails with the first matcher's failure message" do
          expect {
            expect(3).to eq(4).and be >= 2
          }.to fail_with(dedent <<-EOS)
            |
            |expected: 4
            |     got: 3
            |
            |(compared using ==)
            |
          EOS
        end
      end

      context 'when only the second matcher fails' do
        it "fails with the second matcher's failure message" do
          expect {
            expect(3).to be_kind_of(Integer).and eq(4)
          }.to fail_with(dedent <<-EOS)
            |
            |expected: 4
            |     got: 3
            |
            |(compared using ==)
            |
          EOS
        end
      end

      context "when both mathers fail" do
        context "when both matchers have multi-line failure messages" do
          it 'fails with a well formatted message containing both sub-messages' do
            expect {
              expect(3).to eq(4).and be >= 8
            }.to fail_with(dedent <<-EOS)
              |
              |   expected: 4
              |        got: 3
              |
              |   (compared using ==)
              |
              |...and:
              |
              |   expected: >= 8
              |        got:    3
            EOS
          end
        end

        context "when both matchers have single-line failure messages" do
          it 'still fails with a multi-line failure message because it reads better than keeping it on a single line' do
            expect {
              expect("foo").to start_with("a").and end_with("z")
            }.to fail_with(dedent <<-EOS)
              |   expected "foo" to start with "a"
              |
              |...and:
              |
              |   expected "foo" to end with "z"
            EOS
          end
        end

        context "when the first matcher has a multi-line failure message" do
          it 'fails with a well formatted message containing both sub-messages' do
            expect {
              expect("foo").to eq(4).and end_with("z")
            }.to fail_with(dedent <<-EOS)
              |
              |   expected: 4
              |        got: "foo"
              |
              |   (compared using ==)
              |
              |...and:
              |
              |   expected "foo" to end with "z"
            EOS
          end
        end

        context "when the second matcher has a multi-line failure message" do
          it 'fails with a well formatted message containing both sub-messages' do
            expect {
              expect("foo").to end_with("z").and eq(4)
            }.to fail_with(dedent <<-EOS)
              |   expected "foo" to end with "z"
              |
              |...and:
              |
              |   expected: 4
              |        got: "foo"
              |
              |   (compared using ==)
              |
            EOS
          end
        end

        context "when the first matcher is diffable" do
          subject { include("foo").and be_a(String) }

          it 'is diffable' do
            expect(subject).to be_diffable
          end

          context "when only first matcher fails" do
            it 'fails with a message containing a diff for first matcher' do
              expected_failure = dedent(<<-EOS)
                |Diff for (include "foo"):
                |@@ -1,2 +1,3 @@
                |-foo
                |+baz
                |+bar
              EOS

              expect {
                expect(dedent(<<-EOS)).to subject
                  |baz
                  |bar
                EOS
              }.to fail_including(expected_failure)
            end
          end

          context "when only second matcher fails" do
            subject { include("baz").and be_an(Integer) }

            it 'fails with a message not containing a diff for first matcher' do
              expect {
                expect(dedent(<<-EOS)).to subject
                  |baz
                  |bar
                EOS
              }.to fail_with(a_string_excluding "Diff")
            end
          end

          context "when both matcher fail" do
            subject { include("foo").and eq(35) }

            it "fails with a message containing a diff with first matcher" do
              expected_failure = dedent(<<-EOS)
                |   expected "baz\\nbar" to include "foo"
                |
                |...and:
                |
                |   expected: 35
                |        got: "baz\\nbar"
                |
                |   (compared using ==)
                |
                |Diff for (include "foo"):
                |@@ -1,2 +1,3 @@
                |-foo
                |+baz
                |+bar
              EOS

              expect {
                expect(dedent(<<-EOS)).to subject
                  |baz
                  |bar
                EOS
              }.to fail_including(expected_failure)
            end
          end
        end

        context "when the first matcher does not implement #diffable?" do
          subject { matcher_without_diffable.and exist }

          it 'is not diffable' do
            expect(subject).not_to be_diffable
          end
        end

        context "when the second matcher does not implement #diffable?" do
          subject { exist.and matcher_without_diffable }

          it 'is not diffable' do
            expect(subject).not_to be_diffable
          end
        end

        context "when the second matcher is diffable" do
          subject { eq(35).and include("foo") }

          it 'is diffable' do
            expect(subject).to be_diffable
          end

          it 'fails with a message containing a diff for second matcher' do
            expected_failure = dedent(<<-EOS)
              |   expected: 35
              |        got: "baz\\nbar"
              |
              |   (compared using ==)
              |
              |...and:
              |
              |   expected "baz\\nbar" to include "foo"
              |Diff for (include "foo"):
              |@@ -1,2 +1,3 @@
              |-foo
              |+baz
              |+bar
            EOS

            expect {
              expect(dedent(<<-EOS)).to subject
                |baz
                |bar
              EOS
            }.to fail_including(expected_failure)
          end
        end

        context "when both matchers are diffable" do
          subject { include("bar").and include("foo") }

          it 'is diffable' do
            expect(subject).to be_diffable
          end

          it 'fails with a message containing diffs for both matcher' do
            expected_failure = dedent(<<-EOS)
              |   expected "baz\\nbug" to include "bar"
              |
              |...and:
              |
              |   expected "baz\\nbug" to include "foo"
              |Diff for (include "bar"):
              |@@ -1,2 +1,3 @@
              |-bar
              |+baz
              |+bug
              |
              |Diff for (include "foo"):
              |@@ -1,2 +1,3 @@
              |-foo
              |+baz
              |+bug
            EOS

            expect {
              expect(dedent(<<-EOS)).to subject
                |baz
                |bug
              EOS
            }.to fail do |error|
              expect(error.message).to include(expected_failure)
            end
          end
        end

        context "when both matchers are not diffable" do
          subject { be_a(String).and be_truthy }

          it 'is not diffable' do
            expect(subject).not_to be_diffable
          end

          it 'fails with a message not containing any diff' do
            expect {
              expect(35).to subject
            }.to fail_with(a_string_excluding "Diff")
          end
        end
      end
    end

    describe "expect(...).not_to matcher.and(other_matcher)" do
      it "is not supported" do
        expect {
          expect(3).not_to eq(2).and be > 2
        }.to raise_error(NotImplementedError, /matcher.and matcher` is not supported/)
      end
    end

    describe "expect(...).to matcher.or(other_matcher)" do
      it_behaves_like "an RSpec value matcher", :valid_value => 3, :invalid_value => 5, :disallows_negation => true do
        let(:matcher) { eq(3).or eq(4) }
      end

      context 'when using boolean OR `|` alias' do
        it_behaves_like "an RSpec value matcher", :valid_value => 3, :invalid_value => 5, :disallows_negation => true do
          let(:matcher) { eq(3) | eq(4) }
        end
      end

      include_examples "making a copy", :or, :dup
      include_examples "making a copy", :or, :clone
      it_behaves_like  "handles blocks properly", :or

      it 'has a description composed of both matcher descriptions' do
        matcher = eq(3).or eq(4)
        expect(3).to matcher
        expect(matcher.description).to eq("eq 3 or eq 4")
      end

      context 'when both matchers pass' do
        it 'passes' do
          expect("foo").to start_with("f").or end_with("o")
        end
      end

      context 'when only the first matcher passes' do
        it 'passes' do
          expect("foo").to start_with("f").or end_with("z")
        end
      end

      context 'when only the last matcher passes' do
        it 'passes' do
          expect("foo").to start_with("a").or end_with("o")
        end
      end

      context 'when both matchers fail' do
        context "when both matchers have multi-line failure messages" do
          it 'fails with a well formatted message containing both sub-messages' do
            expect {
              expect(3).to eq(4).or be >= 8
            }.to fail_with(dedent <<-EOS)
              |
              |   expected: 4
              |        got: 3
              |
              |   (compared using ==)
              |
              |...or:
              |
              |   expected: >= 8
              |        got:    3
            EOS
          end
        end

        context "when both matchers have single-line failure messages" do
          it 'still fails with a multi-line failure message because it reads better than keeping it on a single line' do
            expect {
              expect("foo").to start_with("a").or end_with("z")
            }.to fail_with(dedent <<-EOS)
              |   expected "foo" to start with "a"
              |
              |...or:
              |
              |   expected "foo" to end with "z"
            EOS
          end
        end

        context "when the first matcher has a multi-line failure message" do
          it 'fails with a well formatted message containing both sub-messages' do
            expect {
              expect("foo").to eq(4).or end_with("z")
            }.to fail_with(dedent <<-EOS)
              |
              |   expected: 4
              |        got: "foo"
              |
              |   (compared using ==)
              |
              |...or:
              |
              |   expected "foo" to end with "z"
            EOS
          end
        end

        context "when the second matcher has a multi-line failure message" do
          it 'fails with a well formatted message containing both sub-messages' do
            expect {
              expect("foo").to end_with("z").or eq(4)
            }.to fail_with(dedent <<-EOS)
              |   expected "foo" to end with "z"
              |
              |...or:
              |
              |   expected: 4
              |        got: "foo"
              |
              |   (compared using ==)
              |
            EOS
          end
        end
      end

      context "when first matcher is diffable" do
        subject { include("foo").or eq(35) }

        it "is diffable" do
          expect(subject).to be_diffable
        end

        it 'fails with a message containing diff for first matcher' do
          expected_failure = dedent(<<-EOS)
            |   expected "baz\\nbug" to include "foo"
            |
            |...or:
            |
            |   expected: 35
            |        got: "baz\\nbug"
            |
            |   (compared using ==)
            |
            |Diff for (include "foo"):
            |@@ -1,2 +1,3 @@
            |-foo
            |+baz
            |+bug
          EOS

          expect {
            expect(dedent(<<-EOS)).to subject
              |baz
              |bug
            EOS
          }.to fail_including(expected_failure)
        end
      end

      context "when second matcher is diffable" do
        subject { eq(35).or include("foo") }

        it "is diffable" do
          expect(subject).to be_diffable
        end

        it 'fails with a message containing diff for second matcher' do
          expected_failure = dedent(<<-EOS)
            |   expected: 35
            |        got: "baz\\nbug"
            |
            |   (compared using ==)
            |
            |...or:
            |
            |   expected "baz\\nbug" to include "foo"
            |Diff for (include "foo"):
            |@@ -1,2 +1,3 @@
            |-foo
            |+baz
            |+bug
          EOS

          expect {
            expect(dedent(<<-EOS)).to subject
              |baz
              |bug
            EOS
          }.to fail_including(expected_failure)
        end
      end

      context "when both matchers are diffable" do
        subject { include("foo").or include("buzz") }

        it "is diffable" do
          expect(subject).to be_diffable
        end

        it 'fails with a message containing diffs for both matcher' do
          expected_failure = dedent(<<-EOS)
            |   expected "baz\\nbug" to include "foo"
            |
            |...or:
            |
            |   expected "baz\\nbug" to include "buzz"
            |Diff for (include "foo"):
            |@@ -1,2 +1,3 @@
            |-foo
            |+baz
            |+bug
            |
            |Diff for (include "buzz"):
            |@@ -1,2 +1,3 @@
            |-buzz
            |+baz
            |+bug
          EOS

          expect {
            expect(dedent(<<-EOS)).to subject
              |baz
              |bug
            EOS
          }.to fail_including(expected_failure)
        end
      end

      context "when both matchers are not diffable" do
        subject { be_a(String).or be_an(Integer) }

        it "is not diffable" do
          expect(subject).not_to be_diffable
        end

        it 'fails with a message containing diffs for both matcher' do
          expect {
            expect(true).to subject
          }.to fail_with(a_string_excluding "Diff")
        end
      end
    end

    context "when chaining many matchers together" do
      it 'can pass appropriately' do
        matcher = start_with("f").and end_with("z").or end_with("o")
        expect("foo").to matcher
        expect(matcher.description).to eq('start with "f" and end with "z" or end with "o"')
      end

      it 'fails with complete diffs if its matchers are diffable' do
        matcher = include("bar").and include("buzz").or include("foo")

        expected_failure = dedent(<<-EOS)
          |   expected "bug\\nsquash" to include "bar"
          |
          |...and:
          |
          |      expected "bug\\nsquash" to include "buzz"
          |
          |   ...or:
          |
          |      expected "bug\\nsquash" to include "foo"
          |Diff for (include "bar"):
          |@@ -1,2 +1,3 @@
          |-bar
          |+bug
          |+squash
          |
          |Diff for (include "buzz"):
          |@@ -1,2 +1,3 @@
          |-buzz
          |+bug
          |+squash
          |
          |Diff for (include "foo"):
          |@@ -1,2 +1,3 @@
          |-foo
          |+bug
          |+squash
        EOS

        expect {
          expect(dedent(<<-EOS)).to matcher
            |bug
            |squash
          EOS
        }.to fail do |error|
          expect(error.message).to include(expected_failure)
        end
      end

      it 'fails with a complete message' do
        expect {
          expect(3).to eq(1).and eq(2).and eq(3).and eq(4)
        }.to fail_with(dedent <<-EOS)
          |
          |   expected: 1
          |        got: 3
          |
          |   (compared using ==)
          |
          |...and:
          |
          |      expected: 2
          |           got: 3
          |
          |      (compared using ==)
          |
          |   ...and:
          |
          |      expected: 4
          |           got: 3
          |
          |      (compared using ==)
          |
        EOS
      end
    end

    describe "expect(...).not_to matcher.or(other_matcher)" do
      it "is not supported" do
        expect {
          expect(3).not_to eq(2).or be > 2
        }.to raise_error(NotImplementedError, /matcher.or matcher` is not supported/)
      end
    end
  end
end
