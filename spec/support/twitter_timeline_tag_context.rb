shared_context "with twitter_timeline_tag" do
  def compose_twitter_timeline_tag_comment(title)
    <<~COMMENT
      #{title}
      {% twitter_timeline https://twitter.com/NYTNow/timelines/576828964162965504 %}
    COMMENT
  end

  def expect_twitter_timeline_tag_to_be_active(count: 1)
    expect(page).to have_css(".ltag-twitter-timeline-body iframe", count: count)
  end

  def expect_no_twitter_timeline_tag_to_be_active
    expect_twitter_timeline_tag_to_be_active count: 0
  end
end
