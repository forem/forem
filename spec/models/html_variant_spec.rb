require "rails_helper"

RSpec.describe HtmlVariant, type: :model do
  let(:html_variant) { create(:html_variant, approved: true, published: true) }

  describe "validations" do
    describe "builtin validations" do
      subject { html_variant }

      it { is_expected.to belong_to(:user).optional }

      it { is_expected.to validate_inclusion_of(:group).in_array(described_class::GROUP_NAMES) }
      it { is_expected.to validate_presence_of(:html) }
      it { is_expected.to validate_uniqueness_of(:name) }
    end
  end

  it "prefixes an image with cloudinary", cloudinary: true do
    html = "<div><img src='https://devimages.com/image.jpg' /></div>"
    html_variant.update(approved: false, html: html)
    cloudinary_string = "/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_420/https://devimages.com/image.jpg"
    expect(html_variant.html).to include(cloudinary_string)
  end

  it "does not add prefix if it already starts with cloudinary" do
    allow(Images::Optimizer).to receive(:call)
    html = %(<img src="https://res.cloudinary.com/image.jpg">)
    html_variant.update(approved: false, html: html)
    expect(Images::Optimizer).not_to have_received(:call)
  end

  it "does not add prefix if already on site root" do
    allow(Images::Optimizer).to receive(:call)
    html = "<img src=\"#{Images::Optimizer.get_imgproxy_endpoint}/image.jpg\">"
    html_variant.update(approved: false, html: html)
    html_variant.save
    expect(Images::Optimizer).not_to have_received(:call)
  end

  it "strips whitespace from the name" do
    variant = create(:html_variant, name: " hello world ")
    expect(variant.reload.name).to eq "hello world"
  end
end
