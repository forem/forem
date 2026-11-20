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

  it "ignores usernames that normalize to fewer than 2 characters" do
    expect(result_from(["a", "-", ".a.", " a "])).to match(%([a-z]+{12}))
  end

  %w[login signup admin].each do |username|
    it "suffixes the reserved username #{username}" do
      expect(result_from([username])).to match(/\A#{username}_\d+\z/)
    end
  end

  it "checks reserved names after normalization" do
    expect(result_from(["Lo.GiN"])).to match(/\Alogin_\d+\z/)
  end

  it "prefers an available supplied username over suffixing a reserved name" do
    expect(result_from(%w[login available_username])).to eq("available_username")
  end

  it "uses the runtime reserved list for route-derived names" do
    allow(ReservedWords).to receive(:all).and_return(["custom_route"])

    expect(result_from(["custom_route"])).to match(/\Acustom_route_\d+\z/)
  end

  it "skips reserved suffixed candidates before using the random fallback" do
    generator = described_class.new(["login"], detector: does_not_exist, generator: -> { "available_username" })
    allow(generator).to receive(:rand).with(100).and_return(7)
    allow(ReservedWords).to receive(:all).and_return(%w[login login_7])

    expect(generator.call).to eq("available_username")
  end

  it "returns nil when every random candidate is reserved" do
    result = described_class.call([], detector: does_not_exist, generator: -> { "login" })

    expect(result).to be_nil
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
