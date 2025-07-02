require "rails_helper"

RSpec.shared_examples "valid notifiable and no mentions" do
  it "does not create mentions if a user is not mentioned" do
    set_markdown_and_save(notifiable, markdown)
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(0)
  end

  it "creates a mention if notifiable is updated to include mention", :aggregate_failures do
    set_markdown_and_save(notifiable, markdown)
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(0)

    set_markdown_and_save(notifiable, mention_markdown)
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(1)
  end

  xit "does not create a mention if notifiable is updated with mention inside code block", :aggregate_failures do
    set_markdown_and_save(notifiable, mention_code_markdown)
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(0)
  end

  it "does not create a mention if notifiable is updated with mention inside code snippet", :aggregate_failures do
    set_markdown_and_save(notifiable, mention_snippet_markdown)
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(0)
  end

  it "does not create a mention if notifiable is updated liquid tag that would render mention-like text",
     :aggregate_failures do
    mock_liquid_template = Liquid::Template.new
    allow(Liquid::Template).to receive(:parse).and_return(mock_liquid_template)
    allow(mock_liquid_template).to receive(:render).and_return(
      "<p>A sample github</p> <div class=\"ltag-github\">Embedded content @#{user.username}</div>",
    )

    set_markdown_and_save(notifiable, mention_liquid)
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(0)
  end
end

RSpec.shared_examples "valid notifiable and has mentions" do
  it "creates mention if there is a user mentioned and if the user doesn't own notifiable" do
    set_markdown_and_save(notifiable, mention_markdown)
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(1)
  end

  it "deletes mention if deleted from notifiable", :aggregate_failures do
    set_markdown_and_save(notifiable, mention_markdown)
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(1)

    set_markdown_and_save(notifiable, "Hello, you are cool.")
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(0)
  end

  it "deletes notifications associated with mention if deleted from notifiable" do
    expect do
      set_markdown_and_save(notifiable, mention_markdown)
      described_class.call(notifiable)
      Notification.send_mention_notification_without_delay(Mention.last)
    end
      .to change { Mention.all.size }.by(1)
      .and change { Notification.all.size }.by(1)

    expect do
      set_markdown_and_save(notifiable, "Hello, you are cool.")
      described_class.call(notifiable)
      Sidekiq::Job.drain_all
    end
      .to change { Mention.all.size }.by(-1)
      .and change { Notification.all.size }.by(-1)
  end

  it "creates one mention even if multiple mentions of same user" do
    set_markdown_and_save(notifiable, "Hello @#{user.username} @#{user.username} @#{user.username}, you rock.")
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(1)
  end

  it "creates multiple mentions for multiple users" do
    user3 = create(:user)

    set_markdown_and_save(notifiable, "Hello @#{user.username} @#{user3.username}, you are cool.")
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(2)
  end

  it "deletes one of multiple mentions if one of multiple is deleted", :aggregate_failures do
    user3 = create(:user)

    set_markdown_and_save(notifiable, "Hello @#{user.username} @#{user3.username}, you are cool.")
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(2)

    set_markdown_and_save(notifiable, "Hello @#{user3.username}, you are cool.")
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(1)
  end

  it "creates a mention on creation of notifiable" do
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(1)
  end

  it "does not create a mention when the user mentions themselves" do
    set_markdown_and_save(notifiable, "Me, Myself and I @#{user2.username}")
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(0)
  end
end

RSpec.shared_examples "valid notifiable with embedded mentions" do
  it "does not create a mention" do
    comment = create(:comment, user_id: user2.id, commentable: article, body_markdown: "Hi there, @#{user.username}")
    liquid_tag_markdown = "Check out this comment: {% comment #{comment.id_code_generated} %}"

    notifiable.update_column(:body_markdown, liquid_tag_markdown)
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(0)
  end
end

RSpec.shared_examples "invalid notifiable and has mentions" do
  it "does not create a mention without valid mentionable" do
    notifiable.update_column(:body_markdown, "")
    described_class.call(notifiable)
    expect(Mention.all.size).to eq(0)
  end
end

RSpec.describe Mentions::CreateAll, type: :service do
  let(:user)               { create(:user) }
  let(:user2)              { create(:user) }
  let(:article)            { create(:article, user_id: user.id) }
  let(:markdown)           { "Hello, you are cool." }
  let(:mention_markdown) { "Hello @#{user.username}, you are cool." }
  let(:mention_snippet_markdown) { "This is how I would mention `@#{user.username}` without a notification" }
  let(:mention_code_markdown) { " ... ``` mention a user @#{user.username} in a code block``` ..." }
  let(:mention_liquid) { " A sample github\n {% github https://github.com/forem/forem/pull/ %} ..." }

  def set_markdown_and_save(notifiable, markdown)
    notifiable.update(body_markdown: markdown)
  end

  it_behaves_like "valid notifiable and no mentions" do
    let(:notifiable) { create(:comment, body_markdown: markdown, user_id: user2.id, commentable: article) }
  end

  it_behaves_like "valid notifiable and has mentions" do
    let(:notifiable) { create(:comment, body_markdown: mention_markdown, user_id: user2.id, commentable: article) }
  end

  it_behaves_like "valid notifiable with embedded mentions" do
    # Explicitly use markdown here without a mention to test that embedded mentions do not trigger a notification.
    let(:notifiable) { create(:comment, body_markdown: markdown, user_id: user2.id, commentable: article) }
  end

  it_behaves_like "invalid notifiable and has mentions" do
    let(:notifiable) { create(:comment, body_markdown: mention_markdown, user_id: user2.id, commentable: article) }
  end

  it_behaves_like "valid notifiable and no mentions" do
    let(:notifiable) { create(:article, user_id: user2.id) }
  end

  it_behaves_like "valid notifiable and has mentions" do
    let(:notifiable) { create(:article, user_id: user2.id) }
    before { notifiable.update!(body_markdown: mention_markdown) }
  end

  it_behaves_like "valid notifiable with embedded mentions" do
    let(:notifiable) { create(:article, user_id: user2.id) }
  end

  it_behaves_like "invalid notifiable and has mentions" do
    let(:notifiable) { create(:article, user_id: user2.id) }
  end
end
