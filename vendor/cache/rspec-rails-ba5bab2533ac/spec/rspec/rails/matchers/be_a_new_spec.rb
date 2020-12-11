RSpec.describe "be_a_new matcher" do
  context "new record" do
    let(:record) do
      Class.new do
        def new_record?; true; end
      end.new
    end
    context "right class" do
      it "passes" do
        expect(record).to be_a_new(record.class)
      end
    end
    context "wrong class" do
      it "fails" do
        expect(record).not_to be_a_new(String)
      end
    end
  end

  context "existing record" do
    let(:record) do
      Class.new do
        def new_record?; false; end
      end.new
    end
    context "right class" do
      it "fails" do
        expect(record).not_to be_a_new(record.class)
      end
    end
    context "wrong class" do
      it "fails" do
        expect(record).not_to be_a_new(String)
      end
    end
  end

  describe "#with" do
    context "right class and new record" do
      let(:record) do
        Class.new do
          def initialize(attributes)
            @attributes = attributes
          end

          def attributes
            @attributes.stringify_keys
          end

          def new_record?; true; end
        end.new(foo: 'foo', bar: 'bar')
      end

      context "all attributes same" do
        it "passes" do
          expect(record).to be_a_new(record.class).with(foo: 'foo', bar: 'bar')
        end
      end

      context "one attribute same" do
        it "passes" do
          expect(record).to be_a_new(record.class).with(foo: 'foo')
        end
      end

      context "with composable matchers" do
        context "one attribute is a composable matcher" do
          it "passes" do
            expect(record).to be_a_new(record.class).with(
              foo: a_string_including("foo"))
          end

          it "fails" do
            expect {
              expect(record).to be_a_new(record.class).with(
                foo: a_string_matching("bar"))
            }.to raise_error("attribute {\"foo\"=>(a string matching \"bar\")} was not set on #{record.inspect}")
          end

          context "matcher is wrong type" do
            it "fails" do
              expect {
                expect(record).to be_a_new(record.class).with(
                  foo: a_hash_including({no_foo: "foo"}))
              }.to raise_error { |e|
                expect(e.message).to eq("no implicit conversion of Hash into String").or eq("can't convert Hash into String")
              }
            end
          end
        end

        context "two attributes are composable matchers" do
          context "both matchers present in actual" do
            it "passes" do
              expect(record).to be_a_new(record.class).with(
                foo: a_string_matching("foo"),
                bar: a_string_matching("bar")
              )
            end
          end

          context "only one matcher present in actual" do
            it "fails" do
              expect {
                expect(record).to be_a_new(record.class).with(
                  foo: a_string_matching("foo"),
                  bar: a_string_matching("barn")
                )
              }.to raise_error("attribute {\"bar\"=>(a string matching \"barn\")} was not set on #{record.inspect}")
            end
          end
        end
      end

      context "no attributes same" do
        it "fails" do
          expect {
            expect(record).to be_a_new(record.class).with(zoo: 'zoo', car: 'car')
          }.to raise_error { |e|
            expect(e.message).to match(/attributes \{.*\} were not set on #{Regexp.escape record.inspect}/)
            expect(e.message).to match(/"zoo"=>"zoo"/)
            expect(e.message).to match(/"car"=>"car"/)
          }
        end
      end

      context "one attribute value not the same" do
        it "fails" do
          expect {
            expect(record).to be_a_new(record.class).with(foo: 'bar')
          }.to raise_error(
            %(attribute {"foo"=>"bar"} was not set on #{record.inspect})
          )
        end
      end
    end

    context "wrong class and existing record" do
      let(:record) do
        Class.new do
          def initialize(attributes)
            @attributes = attributes
          end

          def attributes
            @attributes.stringify_keys
          end

          def new_record?; false; end
        end.new(foo: 'foo', bar: 'bar')
      end

      context "all attributes same" do
        it "fails" do
          expect {
            expect(record).to be_a_new(String).with(foo: 'foo', bar: 'bar')
          }.to raise_error(
            "expected #{record.inspect} to be a new String"
          )
        end
      end

      context "no attributes same" do
        it "fails" do
          expect {
            expect(record).to be_a_new(String).with(zoo: 'zoo', car: 'car')
          }.to raise_error { |e|
            expect(e.message).to match(/expected #{Regexp.escape record.inspect} to be a new String and attributes \{.*\} were not set on #{Regexp.escape record.inspect}/)
            expect(e.message).to match(/"zoo"=>"zoo"/)
            expect(e.message).to match(/"car"=>"car"/)
          }
        end
      end

      context "one attribute value not the same" do
        it "fails" do
          expect {
            expect(record).to be_a_new(String).with(foo: 'bar')
          }.to raise_error(
            "expected #{record.inspect} to be a new String and " +
            %(attribute {"foo"=>"bar"} was not set on #{record.inspect})
          )
        end
      end
    end
  end
end
