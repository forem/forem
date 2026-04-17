shared_context "with runkit_tag" do
  def compose_runkit_comment(title)
    <<~COMMENT
      #{title}
      {% runkit %}
      console.log("#{title}")
      {% endrunkit %}
    COMMENT
  end

  def expect_runkit_tag_to_be_visible(count: 1)
    expect(page).to have_css(".ltag-runkit-fallback", count: count)
  end

  def expect_no_runkit_tag_to_be_visible
    expect_runkit_tag_to_be_visible count: 0
  end
end
