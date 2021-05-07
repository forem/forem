require "rails_helper"

RSpec.describe JsonApiSortParam do
  let!(:controller) do
    Class.new(Api::V0::ApiController) { include JsonApiSortParam }.new
  end

  it "uses the `sort` param of the controller by default" do
    params = ActionController::Parameters.new(sort: "created_at,-updated_at")
    allow(controller).to receive(:params).and_return(params)

    params = controller.parse_sort_param(
      allowed_fields: %i[created_at updated_at],
      default_sort: { created_at: :desc },
    )
    expect(params).to eq({ created_at: :asc, updated_at: :desc })
  end

  it "returns a default sort order if there are no sorting params" do
    params = controller.parse_sort_param(
      "",
      allowed_fields: [:created_at],
      default_sort: { created_at: :desc },
    )
    expect(params).to eq({ created_at: :desc })
  end

  it "filters out non-allowed params", :aggregate_failures do
    params = controller.parse_sort_param(
      "-created_at,updated_at",
      allowed_fields: [:updated_at],
      default_sort: { created_at: :desc },
    )
    expect(params).not_to have_key(:created_at)
    expect(params).to have_key(:updated_at)
  end

  it "generates a sort params hash" do
    params = controller.parse_sort_param(
      "created_at,-updated_at",
      allowed_fields: %i[created_at updated_at],
      default_sort: { created_at: :desc },
    )
    expect(params).to eq({ created_at: :asc, updated_at: :desc })
  end

  it "sorts the params in the correct order" do
    params = controller.parse_sort_param(
      "-updated_at,created_at",
      allowed_fields: %i[created_at updated_at],
      default_sort: { created_at: :desc },
    )
    expect(params.to_a).to eq([%i[created_at asc], %i[updated_at desc]])
  end
end
