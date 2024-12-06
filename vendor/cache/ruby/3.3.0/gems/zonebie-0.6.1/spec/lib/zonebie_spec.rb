require "spec_helper"

describe Zonebie do
  describe "#backend" do
    it "defaults to the activesupport backend in the presence of activesupport" do
      expect(Zonebie.backend.name).to eq :activesupport
    end

    it "allows setting the backend to tzinfo" do
      Zonebie.backend = :tzinfo
      expect(Zonebie.backend.name).to eq :tzinfo
    end

    it "defaults to tzinfo in the absense of activesupport" do
      Zonebie::Backends::ActiveSupport.stubs(:usable?).returns(false)

      expect(Zonebie.backend.name).to eq :tzinfo
    end

    it "does not allow setting the backend to an unsupported value" do
      expect {
        Zonebie.backend = :foobar
      }.to raise_error(ArgumentError)
    end
  end

  describe "#add_backend" do
    it "allows registration of backends classes" do
      expect {
        Zonebie.backend = :my_new_backend
      }.to raise_error(ArgumentError)

      Zonebie.add_backend(stub(:name => :my_new_backend))
      Zonebie.backend = :my_new_backend
    end
  end

  describe "#set_random_timezone" do
    let(:backend) {
      stub_everything(:name  => :my_awesome_backend,
                      :zones => ["Eastern Time (US & Canada)"])
    }

    before do
      Zonebie.add_backend(backend)
      Zonebie.backend = :my_awesome_backend
    end

    it "asks the backend to set the zone" do
      $stdout.stubs(:puts)
      backend.expects(:zone=).with("Eastern Time (US & Canada)")

      Zonebie.set_random_timezone
    end

    it "outputs the timezone to STDOUT" do
      $stdout.expects(:puts).with("[Zonebie] Setting timezone: ZONEBIE_TZ=\"Eastern Time (US & Canada)\"")
      Zonebie.set_random_timezone
    end

    it "does not output the timezone to STDOUT if quiet mode is enabled" do
      $stdout.expects(:puts).never

      Zonebie.quiet = true
      begin
        Zonebie.set_random_timezone
      ensure
        Zonebie.quiet = false
      end
    end

    it "sends the timezone as ENV[ZONEBIE_TZ] if present" do
      $stdout.stubs(:puts)

      backend.expects(:zone=).with("Pacific Time (US & Canada)")

      ENV['ZONEBIE_TZ'] = "Pacific Time (US & Canada)"
      Zonebie.set_random_timezone
    end
  end

  describe "#random_timezone" do
    let(:backend) {
      stub_everything(:name  => :my_awesome_backend,
                      :zones => ["Eastern Time (US & Canada)"])
    }

    before do
      Zonebie.add_backend(backend)
      Zonebie.backend = :my_awesome_backend
    end

    it "returns a random timezone" do
      expect(Zonebie.random_timezone).to eq("Eastern Time (US & Canada)")
    end
  end
end
