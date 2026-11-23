require "rails_helper"

RSpec.describe SubPermissions::Config do
  def config(raw, resource_type: "Billboard")
    described_class.new(raw, resource_type: resource_type)
  end

  let(:valid) { { "version" => 1, "allow" => %w[approve] } }

  it "accepts a version 1 configuration of registered clauses" do
    expect(config(valid)).to be_valid
  end

  it "accepts an empty allow list, which allows no clause" do
    empty = config({ "version" => 1, "allow" => [] })

    expect(empty).to be_valid
    SubPermissions.clauses_for("Billboard").each { |clause| expect(empty.allows?(clause)).to be(false) }
  end

  it "allows only the clauses it lists", :aggregate_failures do
    expect(config(valid).allows?("approve")).to be(true)
    expect(config(valid).allows?(:approve)).to be(true)
    expect(config(valid).allows?("publish")).to be(false)
    expect(config(valid).allows?("modify_approved")).to be(false)
  end

  it "accepts what SubPermissions.build produces" do
    expect(config(SubPermissions.build(allow: %w[publish approve publish]))).to be_valid
  end

  {
    "nil" => nil,
    "a string" => "approve",
    "an array" => %w[approve],
    "JSON null stored as a value" => "null",
    "symbol keys" => { version: 1, allow: %w[approve] },
    "mixed string and symbol keys" => { "version" => 1, :allow => %w[approve] },
    "a missing version" => { "allow" => %w[approve] },
    "a missing allow list" => { "version" => 1 },
    "an unknown key" => { "version" => 1, "allow" => %w[approve], "deny" => %w[publish] },
    "a future version" => { "version" => 2, "allow" => %w[approve] },
    "a string version" => { "version" => "1", "allow" => %w[approve] },
    "a non-array allow list" => { "version" => 1, "allow" => "approve" },
    "a non-string clause" => { "version" => 1, "allow" => [1] },
    "a nested clause" => { "version" => 1, "allow" => [{ "approve" => true }] },
    "duplicate clauses" => { "version" => 1, "allow" => %w[approve approve] },
    "an unknown clause" => { "version" => 1, "allow" => %w[approve delete_everything] },
    "a clause in a different case" => { "version" => 1, "allow" => %w[Approve] }
  }.each do |description, raw|
    it "is invalid and allows nothing with #{description}", :aggregate_failures do
      parsed = config(raw)

      expect(parsed).not_to be_valid
      expect(parsed.errors).to be_present
      SubPermissions.clauses_for("Billboard").each { |clause| expect(parsed.allows?(clause)).to be(false) }
    end
  end

  it "is invalid for a resource type with no registered clauses" do
    parsed = config(valid, resource_type: "Article")

    expect(parsed).not_to be_valid
    expect(parsed.allows?("approve")).to be(false)
  end

  it "names unknown clauses in its error" do
    expect(config({ "version" => 1, "allow" => %w[nope] }).errors.first).to include("nope")
  end
end
