require "rails_helper"

RSpec.describe "Api::V0::Reactions", type: :request do
  let(:user) { create(:user, secret: "TEST_SECRET") }
  let(:article) { create(:article) }

  def create_reaction(user, reactable, category: "like")
    post api_reactions_path(
      reactable_id: reactable.id,
      reactable_type: reactable.class.name,
      category: category,
      key: user.secret,
    )
  end

  describe "POST /api/reactions" do
    context "when authorized as a super admin" do
      before do
        user.add_role(:super_admin)
        sign_in user
      end

      it "returns 422 if the reaction is invalid" do
        create_reaction(user, create(:tag))
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 404 if the key is not found" do
        post api_reactions_path(
          reactable_id: article.id,
          reactable_type: article.class.name,
          category: "like",
          key: "foobar",
        )
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/reactions - articles" do
    context "when authorized as a super admin" do
      before do
        user.add_role(:super_admin)
        sign_in user
      end

      it "creates a new like reaction" do
        expect do
          create_reaction(user, article)
          expect(response).to have_http_status(:ok)
        end.to change(article.reactions, :count).by(1)

        expect(article.reactions.last.category).to eq("like")
      end

      it "creates a new unicorn reaction" do
        expect do
          create_reaction(user, article, category: "unicorn")
          expect(response).to have_http_status(:ok)
        end.to change(article.reactions, :count).by(1)

        expect(article.reactions.last.category).to eq("unicorn")
      end

      it "sends a reaction notification to the article's user" do
        expect do
          sidekiq_perform_enqueued_jobs do
            create_reaction(user, article)
          end

          expect(response).to have_http_status(:ok)
        end.to change(article.user.notifications, :count).by(1)
      end

      it "sends a reaction notification to the article's organization" do
        article.update(organization: create(:organization))

        expect do
          sidekiq_perform_enqueued_jobs do
            create_reaction(user, article)
          end

          expect(response).to have_http_status(:ok)
        end.to change(article.organization.notifications, :count).by(1)
      end
    end

    it "rejects non-authorized users" do
      sign_in user

      create_reaction(user, article)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/reactions - comments" do
    let(:comment) { create(:comment, commentable: article) }

    context "when authorized as a super admin" do
      before do
        user.add_role(:super_admin)
        sign_in user
      end

      it "creates a new like reaction" do
        expect do
          create_reaction(user, comment)
          expect(response).to have_http_status(:ok)
        end.to change(comment.reactions, :count).by(1)

        expect(comment.reactions.last.category).to eq("like")
      end

      it "sends a reaction notification to the comment's user" do
        expect do
          sidekiq_perform_enqueued_jobs do
            create_reaction(user, comment)
          end

          expect(response).to have_http_status(:ok)
        end.to change(comment.user.notifications, :count).by(1)
      end
    end

    it "rejects non-authorized users" do
      sign_in user

      create_reaction(user, comment)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
