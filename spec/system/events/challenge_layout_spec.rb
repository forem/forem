require "rails_helper"

RSpec.describe "Challenge event layout", :js do
  let(:event) { create(:event, type_of: :challenge) }

  before do
    image = Rack::Test::UploadedFile.new(
      Rails.root.join("spec/support/fixtures/images/challenge-cover-wide.png"), "image/png"
    )
    event.update!(cover_image: image)
    event.update!(body_markdown: "![Challenge illustration](#{event.cover_image.url})")
  end

  [1440, 375].each do |width|
    it "contains wide cover and markdown images within a #{width}px viewport" do
      page.current_window.resize_to(width, 1000)
      visit event_path(event.event_name_slug, event.event_variation_slug)

      expect(page).to have_css(".event-show-layout img", count: 2)
      page.evaluate_script(<<~JS)
        Promise.all(Array.from(document.querySelectorAll('.event-show-layout img')).map(image => image.decode()))
      JS
      dimensions = page.evaluate_script(<<~JS)
        ({viewport: document.documentElement.clientWidth, scroll: document.documentElement.scrollWidth,
          images: Array.from(document.querySelectorAll('.event-show-layout img')).map(image => ({
            naturalWidth: image.naturalWidth, right: image.getBoundingClientRect().right
          }))})
      JS

      expect(dimensions["viewport"]).to eq(width)
      expect(dimensions["scroll"]).to be <= width
      expect(dimensions["images"].pluck("naturalWidth")).to all(eq(4096))
      expect(dimensions["images"].pluck("right")).to all(be <= width)
    end
  end
end
