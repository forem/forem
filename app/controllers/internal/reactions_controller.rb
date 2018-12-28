module Internal
  class ReactionsController < ApplicationController
    def update
      # raise
      @reaction = Reaction.find(params[:id])
      @reaction.update(status: params[:reaction][:status])
      redirect_to "/internal/reports"
    end
  end
end
