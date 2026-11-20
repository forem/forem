require "rails_helper"

RSpec.describe FavoritesHelper do
  describe "#favorite_control_tag" do
    let(:article) { create(:article) }
    let(:comment) { create(:comment, commentable: article) }

    def mount_node_for(favoritable, **options)
      html = helper.favorite_control_tag(favoritable, **options)
      Nokogiri::HTML.fragment(html).at_css("[data-favorite-control]")
    end

    context "when the community_favorites feature flag is enabled" do
      before do
        FeatureFlag.add(:community_favorites)
        FeatureFlag.enable(:community_favorites)
      end

      after { FeatureFlag.remove(:community_favorites) }

      it "passes the post wording for the confirmation dialog for an article" do
        node = mount_node_for(article)

        expect(node["data-confirm-title"]).to eq("Give this post a Gem?")
        expect(node["data-confirm-body"]).to eq("Are you sure you want to give this post a Gem?")
        expect(node["data-confirm-submit"]).to eq("Give Gem")
        expect(node["data-confirm-cancel"]).to eq("Cancel")
      end

      it "passes the post wording for the dropdown variant of an article" do
        node = mount_node_for(article, variant: :dropdown)

        expect(node["data-confirm-title"]).to eq("Give this post a Gem?")
        expect(node["data-confirm-body"]).to eq("Are you sure you want to give this post a Gem?")
      end

      it "passes the comment wording for the confirmation dialog for a comment" do
        node = mount_node_for(comment, variant: :comment)

        expect(node["data-confirm-title"]).to eq("Give this comment a Gem?")
        expect(node["data-confirm-body"]).to eq("Are you sure you want to give this comment a Gem?")
        expect(node["data-confirm-submit"]).to eq("Give Gem")
        expect(node["data-confirm-cancel"]).to eq("Cancel")
      end

      it "still passes the existing mount node data" do
        node = mount_node_for(comment, variant: :comment)

        expect(node["data-favoritable-type"]).to eq("Comment")
        expect(node["data-favoritable-id"]).to eq(comment.id.to_s)
        expect(node["data-label-favorite"]).to eq("Pick as gem")
        expect(node["data-modal-title"]).to eq("Gem Picked!")
      end

      it "localizes the confirmation dialog wording" do
        I18n.with_locale(:fr) do
          node = mount_node_for(comment, variant: :comment)

          expect(node["data-confirm-title"]).to eq("Donner une pépite à ce commentaire ?")
          expect(node["data-confirm-cancel"]).to eq("Annuler")
        end

        I18n.with_locale(:pt) do
          node = mount_node_for(article)

          expect(node["data-confirm-title"]).to eq("Dar uma joia a esta publicação?")
          expect(node["data-confirm-cancel"]).to eq("Cancelar")
        end
      end
    end

    context "when the community_favorites feature flag is disabled" do
      it "renders no mount node" do
        expect(helper.favorite_control_tag(article)).to be_nil
      end
    end
  end
end
