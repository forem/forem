# frozen_string_literal: true

require 'test_helper'

class WithModelTest < MiniTest::Test
  with_model :BlogPost do
    table do |t|
      t.string 'title'
      t.text 'content'
      t.timestamps null: false
    end

    model do
      def fancy_title
        "Title: #{title}"
      end
    end
  end

  def test_it_should_act_like_a_normal_active_record_model # rubocop:disable Minitest/MultipleAssertions
    record = BlogPost.create!(title: 'New blog post', content: 'Hello, world!')

    record.reload

    assert_equal 'New blog post', record.title
    assert_equal 'Hello, world!', record.content
    assert record.updated_at

    record.destroy

    assert_raises ActiveRecord::RecordNotFound do
      record.reload
    end
  end

  def test_it_has_the_methods_defined_in_its_model_block
    assert_equal 'Title: New blog post', BlogPost.new(title: 'New blog post').fancy_title
  end
end
