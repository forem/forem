require "rails_helper"

RSpec.describe "Admin updates a tag" do
  let(:super_admin) { create(:user, :super_admin, :without_profile, profile_image: nil) }
  let!(:tag1) { create(:tag, name: "alpha", supported: true, taggings_count: 1) }
  let!(:tag2) { create(:tag, name: "betical", supported: false, taggings_count: 2) }

  before do
    sign_in super_admin
  end

  context "when viewing the default page" do
    before do
      visit admin_tags_path
    end

    it "defaults to viewing all tags sorted by taggings count descending and can sort by tag name",
       :aggregate_failures do
      tag_links = find(".crayons-card").all("tr>td>a")
      expect(tag_links.count).to eq 2
      expect(tag_links[0].text).to include tag2.name
      expect(tag_links[1].text).to include tag1.name

      find_link(text: "Name").click
      sorted_tag_links = find(".crayons-card").all("tr>td>a")
      expect(sorted_tag_links[0].text).to include tag1.name
      expect(sorted_tag_links[1].text).to include tag2.name
    end
  end

  context "when viewing supported tags" do
    it "shows only supported tags", :aggregate_failures do
      visit "#{admin_tags_path}?q[supported_eq]=true"
      expect(page.body).to include tag1.name
      expect(page.body).not_to include tag2.name
    end
  end

  context "when viewing unsupported tags" do
    it "shows only unsupported tags", :aggregate_failures do
      visit "#{admin_tags_path}?q[supported_eq]=false"
      expect(page.body).to include tag2.name
      expect(page.body).not_to include tag1.name
    end
  end
end
