require 'spec_helper'

describe StripeMock do
  describe ".mock" do
    it "yields the given block between starting and stopping StripeMock" do
      expect(StripeMock.instance).to be_nil
      expect(StripeMock.state).to eq "ready"

      StripeMock.mock do
        expect(StripeMock.instance).to be_instance_of StripeMock::Instance
        expect(StripeMock.state).to eq "local"
      end

      expect(StripeMock.instance).to be_nil
      expect(StripeMock.state).to eq "ready"
    end

    it "stops StripeMock if the given block raises an exception" do
      expect(StripeMock.instance).to be_nil
      begin
        StripeMock.mock do
          raise "Uh-oh..."
        end
      rescue
        expect(StripeMock.instance).to be_nil
        expect(StripeMock.state).to eq "ready"
      end
    end
  end
end
