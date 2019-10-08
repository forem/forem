require "rails_helper"

RSpec.describe Users::Delete, type: :service do
  let(:user) { create(:user) }

  def self.call(*args)
    new(*args).call
  end

  it "deletes user" do
    described_class.call(user)
    expect(User.find_by(id: user.id)).to be_nil
  end

  it "busts user profile page" do
    delete = described_class.new(user)
    buster = double
    allow(buster).to receive(:bust)
    delete.instance_variable_set("@cache_buster", buster)
    delete.call
    expect(buster).to have_received(:bust).with("/#{user.username}")
  end
end
