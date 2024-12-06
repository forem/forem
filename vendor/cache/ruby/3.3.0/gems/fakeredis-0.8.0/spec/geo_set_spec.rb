require "spec_helper"

module FakeRedis
  describe "GeoMethods" do
    before do
      @client = Redis.new
    end

    describe "#geoadd" do
      it "should raise when not enough arguments" do
        expect { @client.geoadd("Sicily", []) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'geoadd' command")
        expect { @client.geoadd("Sicily", [13.361389, 38.115556]) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'geoadd' command")
      end

      it "should add items to the set" do
        added_items_count = add_sicily
        expect(added_items_count).to eq(2)
      end

      it "should update existing items" do
        @client.geoadd("Sicily", 13.361389, 38.115556, "Palermo")
        added_items_count = @client.geoadd("Sicily", 13, 39, "Palermo", 15.087269, 37.502669, "Catania")
        expect(added_items_count).to eq(1)
      end
    end

    describe "#geodist" do
      before do
        add_sicily
      end

      it "should return destination between two elements" do
        distance_in_meters = @client.geodist("Sicily", "Palermo", "Catania")
        expect(distance_in_meters).to eq("166412.6051")

        distance_in_feet = @client.geodist("Sicily", "Palermo", "Catania", "ft")
        expect(distance_in_feet).to eq("545973.1137")
      end

      it "should raise for unknown unit name" do
        expect {
          @client.geodist("Sicily", "Palermo", "Catania", "unknown")
        }.to raise_error(Redis::CommandError, "ERR unsupported unit provided. please use m, km, ft, mi")
      end

      it "should return nil when element is missing" do
        expect(@client.geodist("Sicily", "Palermo", "Rome")).to be_nil
      end
    end

    describe "#geohash" do
      before do
        add_sicily
      end

      it "should raise when not enough arguments" do
        expect { @client.geohash("Sicily", []) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'geohash' command")
      end

      it "should return geohashes" do
        geohash = @client.geohash("Sicily", "Palermo")
        expect(geohash).to eq(["sqc8b49rny"])

        geohashes = @client.geohash("Sicily", ["Palermo", "Catania"])
        expect(geohashes).to eq(["sqc8b49rny", "sqdtr74hyu"])
      end

      it "should return nils for nonexistent elements" do
        geohashes = @client.geohash("Sicily", ["Palermo", "Rome"])
        expect(geohashes).to eq(["sqc8b49rny", nil])
      end
    end

    describe "#geopos" do
      it "should return positions (longitude, latitude) for elements" do
        add_sicily
        position = @client.geopos("Sicily", "Catania")
        expect(position).to eq([["15.087269", "37.502669"]])

        positions = @client.geopos("Sicily", ["Palermo", "Catania"])
        expect(positions).to eq([["13.361389", "38.115556"], ["15.087269", "37.502669"]])
      end

      it "should return nil for nonexistent elements" do
        expect(@client.geopos("nonexistent", "nonexistent2")).to be_nil
        add_sicily

        position = @client.geopos("Sicily", "Rome")
        expect(position).to eq([nil])

        positions = @client.geopos("Sicily", ["Rome", "Catania"])
        expect(positions).to eq([nil, ["15.087269", "37.502669"]])
      end
    end

    describe "#georadius" do
      before do
        add_sicily
      end

      it "should return members within specified radius" do
        nearest_cities = @client.georadius("Sicily", 15, 37, 100, "km")
        expect(nearest_cities).to eq(["Catania"])
      end

      it "should sort returned members" do
        nearest_cities = @client.georadius("Sicily", 15, 37, 200, "km", sort: "asc")
        expect(nearest_cities).to eq(["Catania", "Palermo"])

        farthest_cities = @client.georadius("Sicily", 15, 37, 200, "km", sort: "desc")
        expect(farthest_cities).to eq(["Palermo", "Catania"])
      end

      it "should return specified count of members" do
        city = @client.georadius("Sicily", 15, 37, 200, "km", sort: "asc", count: 1)
        expect(city).to eq(["Catania"])
      end

      it "should include additional info for members" do
        cities = @client.georadius("Sicily", 15, 37, 200, "km", "WITHDIST")
        expect(cities).to eq([["Palermo", "190.6009"], ["Catania", "56.4883"]])

        cities = @client.georadius("Sicily", 15, 37, 200, "km", "WITHCOORD")
        expect(cities).to eq [["Palermo", ["13.361389", "38.115556"]], ["Catania", ["15.087269", "37.502669"]]]

        cities = @client.georadius("Sicily", 15, 37, 200, "km", "WITHDIST", "WITHCOORD")
        expect(cities).to eq(
          [["Palermo", "190.6009", ["13.361389", "38.115556"]],
           ["Catania", "56.4883", ["15.087269", "37.502669"]]]
        )
      end
    end

    describe "#georadiusbymember" do
      before do
        add_sicily
      end

      it "should sort returned members" do
        nearest_cities = @client.georadiusbymember("Sicily", "Catania", 200, "km", sort: "asc")
        expect(nearest_cities).to eq(["Catania", "Palermo"])

        farthest_cities = @client.georadiusbymember("Sicily", "Catania", 200, "km", sort: "desc")
        expect(farthest_cities).to eq(["Palermo", "Catania"])
      end

      it "should limit number of returned members" do
        city = @client.georadiusbymember("Sicily", "Catania", 100, "km", count: 1)
        expect(city).to eq(["Catania"])
      end

      it "should include extra info if requested" do
        city = @client.georadiusbymember("Sicily", "Catania", 200, "km", sort: :desc, options: :WITHDIST, count: 1)
        expect(city).to eq([["Palermo", "166.4126"]])
      end
    end

    private

    def add_sicily
      @client.geoadd("Sicily", 13.361389, 38.115556, "Palermo", 15.087269, 37.502669, "Catania")
    end
  end
end
