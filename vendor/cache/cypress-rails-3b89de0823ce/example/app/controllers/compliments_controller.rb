class ComplimentsController < ApplicationController
  def index
    @compliments = Compliment.all
  end

  def update
    Compliment.find(params[:id]).update!(params[:compliment].permit(:text))
    flash[:saved] = true
    redirect_to compliments_path
  end
end
