require "rails_helper"

RSpec.describe Users::UsernameGenerator, type: :service do
  let(:does_not_exist) do
    detector = Object.new
    def detector.exists?(_username)
      false
    end
    detector
  end

  def result_from(usernames)
    described_class.call(usernames, detector: does_not_exist)
  end

  it "returns randomly generated username if empty list is passed" do
    expect(result_from([""])).to match(%([a-z]+{12}))
    expect(result_from([])).to match(%([a-z]+{12}))
  end

  it "returns randomly generated username if bad list is passed" do
    expect(result_from([nil, nil, 123, User])).to match(%([a-z]+{12}))
  end

  it "returns supplied username if does not exist" do
    expect(result_from(["username"])).to eq("username")
  end

  it "returns normalized username" do
    expect(result_from(["user.name"])).to eq("username")
  end

  context "when username already exists" do
    subject(:result) { described_class.call ["username"], detector: username_exists }

    let(:username_exists) do
      detector = Object.new
      def detector.exists?(username)
        username == "username"
      end
      detector
    end

    it "returns supplied username with suffix" do
      expect(result).to match(/username_\d+/)
    end

    context "when all generation methods are exhausted" do
      subject(:result) do
        described_class.call [],
                             detector: username_exists,
                             generator: pseudo_random
      end

      let(:pseudo_random) do
        -> { "username" }
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end
end
