require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220223160059_coerce_identity_auth_data_format.rb",
)

describe DataUpdateScripts::CoerceIdentityAuthDataFormat do
  # make malformed identities
  before do
    # make two we do want to change
    omniauth_mock_twitter_payload

    # rubocop:disable FactoryBot/CreateList
    2.times do
      create(:identity, provider: :twitter, user: create(:user)) do |identity|
        hash = { "info" => { "email" => Faker::Internet.email } }
        identity.update(auth_data_dump: hash)
      end
    end
    # rubocop:enable FactoryBot/CreateList

    # and one we don't want changed
    create(:identity, provider: :twitter, user: create(:user))
  end

  it "changes hash auth data dumps to AuthHash" do
    # we have two malformed identities (with plain hashes for auth_data_dump)
    expect(Identity.where("auth_data_dump ~ '^---\n'").count).to equal(2)

    described_class.new.run

    # all three should be OmniAuth::AuthHash now
    expect(Identity.all.map { |i| i.auth_data_dump.class }.uniq).to eq([OmniAuth::AuthHash])
  end

  it "handles null values safely" do
    id = create(:identity, provider: :twitter, user: create(:user))
    id.update_column(:auth_data_dump, nil)

    described_class.new.run

    auth_data_classes = Identity.all.map { |i| i.auth_data_dump.class }.uniq
    expect(auth_data_classes).to include(OmniAuth::AuthHash, NilClass)
    expect(auth_data_classes).not_to include(Hash)
  end
end
