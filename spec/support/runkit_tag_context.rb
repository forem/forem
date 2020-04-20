shared_context "runkit_tag" do
  def compose_runkit_comment(title)
    <<~COMMENT
      #{title}
      {% runkit %}
      console.log("#{title}")
      {% endrunkit %}
    COMMENT
  end

  def expect_runkit_tag_to_be_active(count: 1)
    expect(page).to have_css(".runkit-element iframe", count: count)
  end
end
