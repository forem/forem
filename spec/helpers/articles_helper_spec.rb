require "rails_helper"

describe ArticlesHelper do
  describe ".get_host_without_www" do
    it "drops the www off of a valid url" do
      host = helper.get_host_without_www("https://www.example.com")
      expect(host).to eq "example.com"
    end

    it "lowercases the host name in general" do
      host = helper.get_host_without_www("https://www.EXAMPLE.COM")
      expect(host).to eq "example.com"
    end

    it "titlecases the host for medium.com and drops .com" do
      host = helper.get_host_without_www("https://www.medium.com")
      expect(host).to eq "Medium"
    end

    it "can handle urls without schemes" do
      host = helper.get_host_without_www("www.example.com")
      expect(host).to eq "example.com"
    end
  end
end
