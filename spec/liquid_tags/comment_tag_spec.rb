require 'rails_helper'

RSpec.describe CommentTag, type: :liquid_template do
  let(:user)        { create(:user) }
  let(:article)     { create(:article, user_id: user.id) }
  let(:comment)     { create(:comment, user_id: user.id, commentable_id: article.id) }
  setup             { Liquid::Template.register_tag('devcomment', CommentTag) }

  def generate_comment_tag(id_code)
    Liquid::Template.parse("{% devcomment #{id_code} %}")
  end

  context 'when given valid id_code' do
    it 'fetches the target comment' do
      liquid = generate_comment_tag(comment.id_code_generated)
      expect(liquid.root.nodelist.first.comment).to eq(comment)
    end

    it 'raise error if comment does not exist' do
      expect do
        generate_comment_tag('this should fail')
      end.to raise_error(StandardError)
    end
  end

  it 'rejects invalid id_code' do
    expect do
      generate_comment_tag('this should fail')
    end.to raise_error(StandardError)
  end
end
