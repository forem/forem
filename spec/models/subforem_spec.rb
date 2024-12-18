require 'rails_helper'

RSpec.describe Subforem, type: :model do
  it "calles cache busting methods after save" do
    subforem = create(:subforem)
    expect(Rails.cache).to receive(:delete).with('settings/general')
    expect(Rails.cache).to receive(:delete).with('subforem_default_id')
    expect(Rails.cache).to receive(:delete).with("subforem_id_by_domain_#{subforem.domain}")
    subforem.save
  end
end
