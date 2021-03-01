require "rails_helper"

RSpec.describe "Admin updates a tag", type: :system do
  let(:super_admin) { create(:user, :super_admin) }
  let!(:tag1) { create(:tag, name: "alpha", supported: true, taggings_count: 1) }
  let!(:tag2) { create(:tag, name: "betical", supported: false, taggings_count: 2) }

  context "when viewing the default page" do
    before do
      sign_in super_admin
      visit admin_tags_path
    end

    it "defaults to viewing all tags" do
      tag_table_body = find(".crayons-card")
      expect(tag_table_body.all("tr>td>a").count).to eq 2
    end

    it "defaults to sorting by taggings count, descending" do
      tag_links = find(".crayons-card").all("tr>td>a")
      expect(tag_links[0].text).to include tag2.name
      expect(tag_links[1].text).to include tag1.name
    end

    it "can sort by other columns, like tag name" do
      find_link(text: "Name").click
      tag_links = find(".crayons-card").all("tr>td>a")
      expect(tag_links[0].text).to include tag1.name
      expect(tag_links[1].text).to include tag2.name
    end
  end

  context "when viewing supported tags" do
    it "shows only supported tags" do
      sign_in super_admin
      visit "#{admin_tags_path}?q[supported_eq]=true"
      expect(page.body).to include tag1.name
      expect(page.body).not_to include tag2.name
    end
  end

  context "when viewing unsupported tags" do
    it "shows only unsupported tags" do
      sign_in super_admin
      visit "#{admin_tags_path}?q[supported_eq]=false"
      expect(page.body).to include tag2.name
      expect(page.body).not_to include tag1.name
    end
  end
end
