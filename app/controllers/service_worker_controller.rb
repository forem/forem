class ServiceWorkerController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_cache_control_headers, only: %i[index]

  def index
    set_surrogate_key_header "serviceworker-js"
    render formats: [:js]
  end
end
