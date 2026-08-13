shared_context "with legacy code tag" do
  def compose_legacy_code_comment(title)
    <<~COMMENT
      #{title}
      {% runkit %}
      console.log("#{title}")
      {% endrunkit %}
    COMMENT
  end

  def expect_legacy_code_tag_to_be_visible(count: 1)
    expect(page).to have_css(".ltag-legacy-code-fallback", count: count)
  end

  def expect_no_legacy_code_tag_to_be_visible
    expect_legacy_code_tag_to_be_visible count: 0
  end
end
