require "rails_helper"

RSpec.describe "User visits the videos page" do
  context "when user hasn't logged in" do
    before { visit "/videos" }

    describe "meta tags" do
      it "contains the qualified community name in og:site_name and the expected title tags", :aggregate_failures do
        expected_title = "Videos - #{community_name}"

        expect(page).to have_css("meta[property='og:site_name'][content='#{community_name}']", visible: :hidden)
        expect(page).to have_title(expected_title)
        expect(page).to have_css("meta[property='og:title'][content='#{expected_title}']", visible: :hidden)
        expect(page).to have_css("meta[name='twitter:title'][content='#{expected_title}']", visible: :hidden)
      end
    end
  end

  context "when additional videos are appended via infinite scroll", :js do
    before { visit "/videos" }

    it "escapes HTML characters in video titles and author names and neutralizes unsafe URLs", :aggregate_failures do
      video_payload = [
        {
          id: 999_001,
          path: "/example_author/demo-video",
          video: "https://www.youtube.com/embed/demo123",
          title: '<b class="formatted-video-title">Demo & Talk</b>',
          video_thumbnail_url: "https://example.com/thumb.png",
          video_duration_in_minutes: "2:30",
          user: { name: '<i class="formatted-video-author">Alex</i>' }
        },
        {
          id: 999_002,
          path: "/\\evil.example/phish",
          video: "javascript://youtube.com/%0aalert(1)",
          title: '<b class="formatted-thumb-title">Thumb & Talk</b>',
          video_thumbnail_url: "javascript:alert(1)",
          video_duration_in_minutes: '<span class="formatted-duration">1:45</span>',
          user: { name: '<i class="formatted-thumb-author">Sam</i>' }
        },
      ]

      page.execute_script("insertVideos(arguments[0])", video_payload)

      within("#video-article-999001") do
        expect(page).to have_text('<b class="formatted-video-title">Demo & Talk</b>')
        expect(page).to have_text('<i class="formatted-video-author">Alex</i>')
        expect(page).to have_no_css("b.formatted-video-title")
        expect(page).to have_no_css("i.formatted-video-author")
        expect(page).to have_css('iframe[src="https://www.youtube.com/embed/demo123"]')
      end

      expect(page).to have_css('#video-article-999002[href="#"]')
      within("#video-article-999002") do
        expect(page).to have_no_css("iframe")
        expect(page).to have_css('img[src=""]')
        expect(page).to have_text('<b class="formatted-thumb-title">Thumb & Talk</b>')
        expect(page).to have_text('<i class="formatted-thumb-author">Sam</i>')
        expect(page).to have_text('<span class="formatted-duration">1:45</span>')
        expect(page).to have_no_css("b.formatted-thumb-title")
        expect(page).to have_no_css("i.formatted-thumb-author")
        expect(page).to have_no_css("span.formatted-duration")
      end
    end
  end
end
