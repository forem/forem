RSpec.describe "expect(...).to start_with" do
  it_behaves_like "an RSpec value matcher", :valid_value => "ab", :invalid_value => "bc" do
    let(:matcher) { start_with("a") }
  end

  context "with a string" do
    it "passes if it matches the start of the actual string" do
      expect("this string").to start_with "this str"
    end

    it "fails if it does not match the start of the actual string" do
      expect {
        expect("this string").to start_with "that str"
      }.to fail_with("expected \"this string\" to start with \"that str\"")
    end
  end

  context "with an array" do
    it "passes if it is the first element of the array" do
      expect([0, 1, 2]).to start_with 0
    end

    it "passes if the first elements of the array match" do
      expect([0, 1, 2]).to start_with 0, 1
    end

    it "fails if it does not match the first element of the array" do
      expect {
        expect([0, 1, 2]).to start_with 2
      }.to fail_with("expected [0, 1, 2] to start with 2")
    end

    it "fails if it the first elements of the array do not match" do
      expect {
        expect([0, 1, 2]).to start_with 1, 2
      }.to fail_with("expected [0, 1, 2] to start with 1 and 2")
    end
  end

  context "with an array of strings" do
    it "passes if given the first element of the array" do
      expect(%w[ a b c ]).to start_with 'a'
    end

    it "passes if given the first n of the array" do
      expect(%w[ a b c ]).to start_with('a', 'b')
    end

    it 'fails if given the wrong first element of the array' do
      expect {
        expect(%w[ a b c ]).to start_with 'z'
      }.to fail_with('expected ["a", "b", "c"] to start with "z"')
    end
  end

  context "with an array of uncustomized structs" do
    struct = Struct.new(:foo)

    it 'passes if the array ends with a struct equal to the provided struct' do
      s1 = struct.new(5)
      s2 = struct.new(5)
      expect(s1).to eq(s2)

      expect([s1, 10]).to start_with(s2)
    end

    it 'fails if the array ends with a struct not equal to the provided struct' do
      s1 = struct.new(5)
      s2 = struct.new(6)
      expect(s1).not_to eq(s2)

      expect {
        expect([s1, 10]).to start_with(s2)
      }.to fail_including("expected [#{s1.inspect}, 10] to start with #{s2.inspect}")
    end
  end

  context "with an array of structs that have a custom `==` definition" do
    my_struct = Struct.new(:id, :fluff) do
      def ==(other)
        other.is_a?(self.class) && other.id == id
      end
    end

    it 'passes if the array ends with a struct equal to the provided struct' do
      s1 = my_struct.new(1, "foo")
      s2 = my_struct.new(1, "bar")
      expect(s1).to eq(s2)

      expect([s1, 10]).to start_with(s2)
    end

    it 'fails if the array ends with a struct not equal to the provided struct' do
      s1 = my_struct.new(1, "foo")
      s2 = my_struct.new(2, "bar")
      expect(s1).not_to eq(s2)

      expect {
        expect([s1, 10]).to start_with(s2)
      }.to fail_including("expected [#{s1.inspect}, 10] to start with #{s2.inspect}")
    end
  end

  context "with an object that does not respond to :[]" do
    it "fails with a useful message" do
      actual = Object.new
      expect {
        expect(actual).to start_with 0
      }.to fail_with("expected #{actual.inspect} to start with 0, but it cannot be indexed using #[]")
    end
  end

  context "with a hash" do
    it "fails with a useful error if trying to match more than one element" do
      actual   = { :a => 'b', :b => 'b', :c => 'c' }
      expected = { :a => 'b', :b => 'b' }
      expect {
        expect(actual).to start_with(expected)
      }.to fail_with(/\Aexpected #{hash_inspect(actual).gsub(" => ", "=>")} to start with #{hash_inspect(expected).gsub(" => ", "=>")}, but it does not have ordered elements\z/)
    end
  end

  describe "composing with other matchers" do
    it 'passes if the start of an array matches two given matchers' do
      expect([1.01, "food", 3]).to start_with(a_value_within(0.2).of(1), a_string_matching(/foo/))
    end

    it 'passes if the start of an array matches one given matcher' do
      expect([1.01, "food", 3]).to start_with(a_value_within(0.2).of(1))
    end

    it 'provides a description' do
      description = start_with(a_value_within(0.1).of(1), a_string_matching(/abc/)).description
      expect(description).to eq("start with a value within 0.1 of 1 and a string matching /abc/")
    end

    it 'fails with a clear error message when the matchers do not match' do
      expect {
        expect([2.01, "food", 3]).to start_with(a_value_within(0.2).of(1), a_string_matching(/foo/))
      }.to fail_with('expected [2.01, "food", 3] to start with a value within 0.2 of 1 and a string matching /foo/')
    end
  end
end

RSpec.describe "expect(...).not_to start_with" do
  context "with a string" do
    it "passes if it does not match the start of the actual string" do
      expect("this string").not_to start_with "that str"
    end

    it "fails if it does match the start of the actual string" do
      expect {
        expect("this string").not_to start_with "this str"
      }.to fail_with("expected \"this string\" not to start with \"this str\"")
    end
  end

  context "with an array" do
    it "passes if it is not the first element of the array" do
      expect([0, 1, 2]).not_to start_with 2
    end

    it "passes if the first elements of the array do not match" do
      expect([0, 1, 2]).not_to start_with 1, 2
    end

    it "fails if it matches the first element of the array" do
      expect {
        expect([0, 1, 2]).not_to start_with 0
      }.to fail_with("expected [0, 1, 2] not to start with 0")
    end

    it "fails if it the first elements of the array match" do
      expect {
        expect([0, 1, 2]).not_to start_with 0, 1
      }.to fail_with("expected [0, 1, 2] not to start with 0 and 1")
    end
  end

  context "with an array of strings" do
    it "fails if given the first element of the array" do
      expect {
        expect(%w[ a b c ]).not_to start_with 'a'
      }.to fail_with('expected ["a", "b", "c"] not to start with "a"')
    end

    it "fails if given the first n of the array" do
      expect {
        expect(%w[ a b c ]).not_to start_with('a', 'b')
      }.to fail_with('expected ["a", "b", "c"] not to start with "a" and "b"')
    end

    it 'passes if given the wrong first element of the array' do
      expect(%w[ a b c ]).not_to start_with 'z'
    end
  end

  it 'can pass when composed with another matcher' do
    expect(["a"]).not_to start_with(a_string_matching(/bar/))
  end

  it 'can fail when composed with another matcher' do
    expect {
      expect(["a"]).not_to start_with(a_string_matching(/a/))
    }.to fail_with('expected ["a"] not to start with a string matching /a/')
  end
end

RSpec.describe "expect(...).to end_with" do
  it_behaves_like "an RSpec value matcher", :valid_value => "ab", :invalid_value => "bc" do
    let(:matcher) { end_with("b") }
  end

  context "with a string" do
    it "passes if it matches the end of the actual string" do
      expect("this string").to end_with "is string"
    end

    it "fails if it does not match the end of the actual string" do
      expect {
        expect("this string").to end_with "is stringy"
      }.to fail_with("expected \"this string\" to end with \"is stringy\"")
    end
  end

  context "with an array" do
    it "passes if it is the last element of the array" do
      expect([0, 1, 2]).to end_with 2
    end

    it "passes if the last elements of the array match" do
      expect([0, 1, 2]).to end_with [1, 2]
    end

    it "fails if it does not match the last element of the array" do
      expect {
        expect([0, 1, 2]).to end_with 1
      }.to fail_with("expected [0, 1, 2] to end with 1")
    end

    it "fails if it the last elements of the array do not match" do
      expect {
        expect([0, 1, 2]).to end_with [0, 1]
      }.to fail_with("expected [0, 1, 2] to end with 0 and 1")
    end
  end

  context "with an array of strings" do
    it "passes if given the last element of the array" do
      expect(%w[ a b c ]).to end_with 'c'
    end

    it "passes if given the last n of the array" do
      expect(%w[ a b c ]).to end_with('b', 'c')
    end

    it 'fails if given the wrong last element of the array' do
      expect {
        expect(%w[ a b c ]).to end_with 'z'
      }.to fail_with('expected ["a", "b", "c"] to end with "z"')
    end
  end

  context "with an array of uncustomized structs" do
    struct = Struct.new(:foo)

    it 'passes if the array ends with a struct equal to the provided struct' do
      s1 = struct.new(5)
      s2 = struct.new(5)
      expect(s1).to eq(s2)

      expect([10, s1]).to end_with(s2)
    end

    it 'fails if the array ends with a struct not equal to the provided struct' do
      s1 = struct.new(5)
      s2 = struct.new(6)
      expect(s1).not_to eq(s2)

      expect {
        expect([10, s1]).to end_with(s2)
      }.to fail_including("expected [10, #{s1.inspect}] to end with #{s2.inspect}")
    end
  end

  context "with an array of structs that have a custom `==` definition" do
    my_struct = Struct.new(:id, :fluff) do
      def ==(other)
        other.is_a?(self.class) && other.id == id
      end
    end

    it 'passes if the array ends with a struct equal to the provided struct' do
      s1 = my_struct.new(1, "foo")
      s2 = my_struct.new(1, "bar")
      expect(s1).to eq(s2)

      expect([10, s1]).to end_with(s2)
    end

    it 'fails if the array ends with a struct not equal to the provided struct' do
      s1 = my_struct.new(1, "foo")
      s2 = my_struct.new(2, "bar")
      expect(s1).not_to eq(s2)

      expect {
        expect([10, s1]).to end_with(s2)
      }.to fail_including("expected [10, #{s1.inspect}] to end with #{s2.inspect}")
    end
  end

  context "with an object that does not respond to :[]" do
    it "fails with a useful message" do
      actual = Object.new
      expect {
        expect(actual).to end_with 0
      }.to fail_with("expected #{actual.inspect} to end with 0, but it cannot be indexed using #[]")
    end
  end

  context "with a hash" do
    it "raises an ArgumentError if trying to match more than one element" do
      actual   = { :a => 'b', :b => 'b', :c => 'c' }
      expected = { :a => 'b', :b => 'b' }
      expect {
        expect(actual).to end_with(expected)
      }.to fail_with(/\Aexpected #{hash_inspect(actual).gsub(" => ", "=>")} to end with #{hash_inspect(expected).gsub(" => ", "=>")}, but it does not have ordered elements\z/)
    end
  end

  describe "composing with other matchers" do
    it 'passes if the end of an array matches two given matchers' do
      expect([3, "food", 1.1]).to end_with(a_string_matching(/foo/), a_value_within(0.2).of(1))
    end

    it 'passes if the end of an array matches one given matcher' do
      expect([3, "food", 1.1]).to end_with(a_value_within(0.2).of(1))
    end

    it 'provides a description' do
      description = end_with(a_value_within(0.1).of(1), a_string_matching(/abc/)).description
      expect(description).to eq("end with a value within 0.1 of 1 and a string matching /abc/")
    end

    it 'fails with a clear error message when the matchers do not match' do
      expect {
        expect([2.01, 3, "food"]).to end_with(a_value_within(0.2).of(1), a_string_matching(/foo/))
      }.to fail_with('expected [2.01, 3, "food"] to end with a value within 0.2 of 1 and a string matching /foo/')
    end
  end
end

RSpec.describe "expect(...).not_to end_with" do
  context "with a sting" do
    it "passes if it does not match the end of the actual string" do
      expect("this string").not_to end_with "stringy"
    end

    it "fails if it matches the end of the actual string" do
      expect {
        expect("this string").not_to end_with "string"
      }.to fail_with("expected \"this string\" not to end with \"string\"")
    end
  end

  context "an array" do
    it "passes if it is not the last element of the array" do
      expect([0, 1, 2]).not_to end_with 1
    end

    it "passes if the last elements of the array do not match" do
      expect([0, 1, 2]).not_to end_with [0, 1]
    end

    it "fails if it matches the last element of the array" do
      expect {
        expect([0, 1, 2]).not_to end_with 2
      }.to fail_with("expected [0, 1, 2] not to end with 2")
    end

    it "fails if it the last elements of the array match" do
      expect {
        expect([0, 1, 2]).not_to end_with [1, 2]
      }.to fail_with("expected [0, 1, 2] not to end with 1 and 2")
    end
  end

  context "with an array of strings" do
    it "fails if given the last element of the array" do
      expect {
        expect(%w[ a b c ]).not_to end_with 'c'
      }.to fail_with('expected ["a", "b", "c"] not to end with "c"')
    end

    it "fails if given the last n of the array" do
      expect {
        expect(%w[ a b c ]).not_to end_with('b', 'c')
      }.to fail_with('expected ["a", "b", "c"] not to end with "b" and "c"')
    end

    it 'passes if given the wrong last element of the array' do
      expect(%w[ a b c ]).not_to end_with 'z'
    end
  end

  it 'can pass when composed with another matcher' do
    expect(["a"]).not_to end_with(a_string_matching(/bar/))
  end

  it 'can fail when composed with another matcher' do
    expect {
      expect(["a"]).not_to end_with(a_string_matching(/a/))
    }.to fail_with('expected ["a"] not to end with a string matching /a/')
  end
end
