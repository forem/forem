require "rails_helper"

RSpec.describe ValidDomainCsvValidator do
  let(:validatable) do
    Class.new do
      def self.name
        "Validatable"
      end
      include ActiveModel::Validations
      attr_accessor :domains

      validates :domains, valid_domain_csv: true
    end
  end
  let(:model) { validatable.new }

  it "marks valid a domain with dashes in the middle" do
    model.domains = ["seo-hunt.com"]
    expect(model).to be_valid
  end

  it "marks valid a two character domain" do
    model.domains = ["2u.com"]
    expect(model).to be_valid
  end

  it "marks invalid a domain with a dash as a prefix" do
    model.domains = ["-seo-hunt.com"]
    expect(model).to be_invalid
  end

  it "marks valid an array of domains" do
    model.domains = ["hello.com", "world.org"]
    expect(model).to be_valid
  end

  it "marks invalid an array of domains if one is invalid" do
    model.domains = ["hello.com", "world.org", "notadomain"]
    expect(model).to be_invalid
  end
end
