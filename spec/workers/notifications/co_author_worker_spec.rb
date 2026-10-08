require "rails_helper"

RSpec.describe Notifications::CoAuthorWorker, type: :worker do
  subject(:worker) { described_class.new }

  let(:article) { create(:article) }
  let(:removed_user_ids) { [1, 2] }

  before do
    allow(Notifications::CoAuthor::Remove).to receive(:call)
    allow(Notifications::CoAuthor::Send).to receive(:call)
  end

  it "calls Remove and Send when the article exists" do
    worker.perform(article.id, removed_user_ids)

    expect(Notifications::CoAuthor::Remove).to have_received(:call).with(article.id, removed_user_ids)
    expect(Notifications::CoAuthor::Send).to have_received(:call).with(article)
  end

  it "defaults removed_user_ids to an empty array" do
    worker.perform(article.id)

    expect(Notifications::CoAuthor::Remove).to have_received(:call).with(article.id, [])
    expect(Notifications::CoAuthor::Send).to have_received(:call).with(article)
  end

  it "calls Remove but skips Send when the article does not exist" do
    non_existent_id = -1
    worker.perform(non_existent_id, removed_user_ids)

    expect(Notifications::CoAuthor::Remove).to have_received(:call).with(non_existent_id, removed_user_ids)
    expect(Notifications::CoAuthor::Send).not_to have_received(:call)
  end
end
