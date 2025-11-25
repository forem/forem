require "rails_helper"

RSpec.describe Admin::BillboardPlacementAreaConfigsController, type: :controller do
  include Devise::Test::ControllerHelpers
  
  let(:admin_user) { create(:user, :super_admin) }
  let(:config) do
    BillboardPlacementAreaConfig.create!(
      placement_area: "sidebar_left",
      signed_in_rate: 50,
      signed_out_rate: 75,
      selection_weights: {
        "random_selection" => 10,
        "new_and_priority" => 20,
        "new_only" => 5,
        "weighted_performance" => 65
      }
    )
  end

  before do
    sign_in admin_user
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "loads all configs ordered by placement_area" do
      config1 = BillboardPlacementAreaConfig.create!(
        placement_area: "sidebar_left",
        signed_in_rate: 50,
        signed_out_rate: 50
      )
      config2 = BillboardPlacementAreaConfig.create!(
        placement_area: "feed_first",
        signed_in_rate: 75,
        signed_out_rate: 75
      )

      get :index
      expect(assigns(:configs)).to include(config1, config2)
    end

    it "creates missing configs for all placement areas" do
      # Delete all existing configs
      BillboardPlacementAreaConfig.destroy_all

      expect do
        get :index
      end.to change(BillboardPlacementAreaConfig, :count).by(Billboard::ALLOWED_PLACEMENT_AREAS.count)
    end

    it "handles errors when creating missing configs gracefully" do
      # Stub create! to raise an error for one area
      allow(BillboardPlacementAreaConfig).to receive(:create!).and_call_original
      allow(BillboardPlacementAreaConfig).to receive(:create!)
        .with(hash_including(placement_area: "sidebar_left"))
        .and_raise(ActiveRecord::RecordInvalid.new(BillboardPlacementAreaConfig.new))

      expect(Rails.logger).to receive(:warn).with(/Failed to create config/)
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #edit" do
    it "returns http success" do
      get :edit, params: { id: config.id }
      expect(response).to have_http_status(:success)
    end

    it "loads the config" do
      get :edit, params: { id: config.id }
      expect(assigns(:config)).to eq(config)
    end

    it "sets the human readable area name" do
      get :edit, params: { id: config.id }
      expect(assigns(:human_readable_area)).to eq("Sidebar Left (First Position)")
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      let(:valid_params) do
        {
          id: config.id,
          billboard_placement_area_config: {
            signed_in_rate: 80,
            signed_out_rate: 60,
            selection_weights: {
              random_selection: 15,
              new_and_priority: 25,
              new_only: 10,
              weighted_performance: 50
            }
          }
        }
      end

      it "updates the config" do
        patch :update, params: valid_params
        config.reload
        expect(config.signed_in_rate).to eq(80)
        expect(config.signed_out_rate).to eq(60)
        expect(config.selection_weights["random_selection"]).to eq(15)
      end

      it "redirects to index with success message" do
        patch :update, params: valid_params
        expect(response).to redirect_to(admin_billboard_placement_area_configs_path)
        expect(flash[:success]).to eq("Placement area config updated successfully")
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          id: config.id,
          billboard_placement_area_config: {
            signed_in_rate: 150, # Invalid: > 100
            signed_out_rate: 60
          }
        }
      end

      it "does not update the config" do
        original_rate = config.signed_in_rate
        patch :update, params: invalid_params
        config.reload
        expect(config.signed_in_rate).to eq(original_rate)
      end

      it "renders edit template with error message" do
        patch :update, params: invalid_params
        expect(response).to render_template(:edit)
        expect(flash[:danger]).to be_present
      end
    end

    context "with edge case params" do
      it "sanitizes negative weight values to 0" do
        patch :update, params: {
          id: config.id,
          billboard_placement_area_config: {
            signed_in_rate: 50,
            signed_out_rate: 50,
            selection_weights: {
              random_selection: -5, # Should be converted to 0
              new_and_priority: 30,
              new_only: 5,
              weighted_performance: 65
            }
          }
        }
        config.reload
        expect(config.selection_weights["random_selection"]).to eq(0)
      end

      it "converts string weights to integers" do
        patch :update, params: {
          id: config.id,
          billboard_placement_area_config: {
            signed_in_rate: 50,
            signed_out_rate: 50,
            selection_weights: {
              random_selection: "10",
              new_and_priority: "20",
              new_only: "5",
              weighted_performance: "65"
            }
          }
        }
        config.reload
        expect(config.selection_weights["random_selection"]).to eq(10)
        expect(config.selection_weights["new_and_priority"]).to eq(20)
      end

      it "handles empty selection_weights" do
        patch :update, params: {
          id: config.id,
          billboard_placement_area_config: {
            signed_in_rate: 50,
            signed_out_rate: 50,
            selection_weights: {}
          }
        }
        expect(response).to redirect_to(admin_billboard_placement_area_configs_path)
      end

      it "handles all zero weights" do
        expect(Rails.logger).to receive(:warn).with(/All selection weights are zero/)
        
        patch :update, params: {
          id: config.id,
          billboard_placement_area_config: {
            signed_in_rate: 50,
            signed_out_rate: 50,
            selection_weights: {
              random_selection: 0,
              new_and_priority: 0,
              new_only: 0,
              weighted_performance: 0
            }
          }
        }
        
        config.reload
        expect(config.selection_weights.values.sum).to eq(0)
      end
    end
  end
end

