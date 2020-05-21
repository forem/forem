class CodelandController < ApplicationController
  # No authorization required for viewing Codeland

  def show
    return if Flipper[:codeland].enabled?(current_user)

    redirect_to "/"
  end
end
