class Internal::UsersController < Internal::ApplicationController
  layout 'internal'

  def index
    @users = User.where.not(feed_url: nil)
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    # Only used for stripping user right now.
    @user = User.find(params[:id])
    strip_user(@user)
    redirect_to "/internal/users/#{@user.id}/edit"
  end

  def strip_user(user)
    return unless user.comments.where("created_at < ?", 7.days.ago).empty?
    user.summary = ""
    user.twitter_username = ""
    user.github_username = ""
    user.website_url = ""
    user.add_role :banned
    unless user.notes.where(reason: "banned").any?
      user.notes.create!(reason: "banned", content: "spam account")
    end
    user.comments.each do |comment|
      comment.reactions.each &:destroy!
      comment.destroy!
    end
    user.articles.each &:destroy!
    user.save!
  rescue => e
    flash[:error] = e.message
  end
end
