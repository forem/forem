require 'rails_helper'

RSpec.describe TagSubforemRelationship, type: :model do
  describe "associations" do
    it { should belong_to(:tag) }
    it { should belong_to(:subforem) }
  end

  describe "validations" do
    it { should validate_presence_of(:tag_id) }
    it { should validate_presence_of(:subforem_id) }
  end

  describe "database columns" do
    it { should have_db_column(:tag_id).of_type(:integer) }
    it { should have_db_column(:subforem_id).of_type(:integer) }
  end
end
