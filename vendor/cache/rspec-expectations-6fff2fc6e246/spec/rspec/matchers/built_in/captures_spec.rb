RSpec.describe "expect(regex).to match(string).with_captures" do
  context "with a string target" do
    it "does match a regex with a missing capture" do
      expect("a123a").to match(/(a)(b)?/).with_captures("a", nil)
    end

    it "does not match a regex with an incorrect match" do
      expect("a123a").not_to match(/(a)/).with_captures("b")
    end

    it "matches a regex without named captures" do
      expect("a123a").to match(/(a)/).with_captures("a")
    end

    it "uses the match description if the regex doesn't match" do
      expect {
        expect(/(a)/).to match("123").with_captures
      }.to fail_with(/expected \/\(a\)\/ to match "123"/)
    end

    if RUBY_VERSION != "1.8.7"
      it "matches a regex with named captures" do
        expect("a123a").to match(Regexp.new("(?<num>123)")).with_captures(:num => "123")
      end

      it "matches a regex with a nested matcher" do
        expect("a123a").to match(Regexp.new("(?<num>123)(asdf)?")).with_captures(a_hash_including(:num => "123"))
      end

      it "does not match a regex with an incorrect named group match" do
        expect("a123a").not_to match(Regexp.new("(?<name>a)")).with_captures(:name => "b")
      end

      it "has a sensible failure description with a hash including matcher" do
        expect {
          expect("a123a").not_to match(Regexp.new("(?<num>123)(asdf)?")).with_captures(a_hash_including(:num => "123"))
        }.to fail_with(/num => "123"/)
      end

      it "matches named captures when not passing a hash" do
        expect("a123a").to match(Regexp.new("(?<num>123)")).with_captures("123")
      end
    end
  end

  context "with a regex target" do
    it "does match a regex with a missing capture" do
      expect(/(a)(b)?/).to match("a123a").with_captures("a", nil)
    end

    it "does not match a regex with an incorrect match" do
      expect(/(a)/).not_to match("a123a").with_captures("b")
    end

    it "matches a regex without named captures" do
      expect(/(a)/).to match("a123a").with_captures("a")
    end

    it "uses the match description if the regex doesn't match" do
      expect {
        expect(/(a)/).to match("123").with_captures
      }.to fail_with(/expected \/\(a\)\/ to match "123"/)
    end

    if RUBY_VERSION != "1.8.7"
      it "matches a regex with named captures" do
        expect(Regexp.new("(?<num>123)")).to match("a123a").with_captures(:num => "123")
      end

      it "matches a regex with a nested matcher" do
        expect(Regexp.new("(?<num>123)(asdf)?")).to match("a123a").with_captures(a_hash_including(:num => "123"))
      end

      it "does not match a regex with an incorrect named group match" do
        expect(Regexp.new("(?<name>a)")).not_to match("a123a").with_captures(:name => "b")
      end

      it "has a sensible failure description with a hash including matcher" do
        expect {
          expect(Regexp.new("(?<num>123)(asdf)?")).not_to match("a123a").with_captures(a_hash_including(:num => "123"))
        }.to fail_with(/num => "123"/)
      end

      it "matches named captures when not passing a hash" do
        expect(Regexp.new("(?<num>123)")).to match("a123a").with_captures("123")
      end
    end
  end
end
