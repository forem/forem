Model specs are marked by `:type => :model` or if you have set
`config.infer_spec_type_from_file_location!` by placing them in `spec/models`.

A model spec is a thin wrapper for an ActiveSupport::TestCase, and includes all
of the behavior and assertions that it provides, in addition to RSpec's own
behavior and expectations.

## Examples

    require "rails_helper"

    RSpec.describe Post, :type => :model do
      context "with 2 or more comments" do
        it "orders them in reverse chronologically" do
          post = Post.create!
          comment1 = post.comments.create!(:body => "first comment")
          comment2 = post.comments.create!(:body => "second comment")
          expect(post.reload.comments).to eq([comment2, comment1])
        end
      end
    end
