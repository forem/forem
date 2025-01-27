require 'rails_helper'

RSpec.describe Subforem, type: :model do
  it "calls subforem_default_idods after save" do
    subforem = create(:subforem)
    expect(Rails.cache).to receive(:delete).with('settings/general')
    expect(Rails.cache).to receive(:delete).with("settings/general-#{subforem.id}")
    expect(Rails.cache).to receive(:delete).with('cached_domains')
    expect(Rails.cache).to receive(:delete).with('subforem_id_to_domain_hash')
    expect(Rails.cache).to receive(:delete).with('subforem_postable_array')
    expect(Rails.cache).to receive(:delete).with('subforem_root_id')
    expect(Rails.cache).to receive(:delete).with('subforem_default_domain')
    expect(Rails.cache).to receive(:delete).with('subforem_root_domain')
    expect(Rails.cache).to receive(:delete).with('subforem_all_domains')
    expect(Rails.cache).to receive(:delete).with('subforem_default_id')
    expect(Rails.cache).to receive(:delete).with("subforem_id_by_domain_#{subforem.domain}")
    subforem.save
  end
end
