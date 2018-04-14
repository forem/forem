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
    new_name = "spam_#{rand(10000)}"
    new_username = "spam_#{rand(10000)}"
    if User.find_by(name: new_name) || User.find_by(username: new_username)
      new_name = "spam_#{rand(10000)}"
      new_username = "spam_#{rand(10000)}"
    end
    user.name = new_name
    user.username = new_username
    user.twitter_username = ""
    user.github_username = ""
    user.website_url = ""
    user.summary = ""
    user.location = ""
    user.education = ""
    user.employer_name = ""
    user.employer_url = ""
    user.employment_title = ""
    user.mostly_work_with = ""
    user.currently_learning = ""
    user.currently_hacking_on = ""
    user.available_for = ""
    user.email_public = false
    user.add_role :banned
    unless user.notes.where(reason: "banned").any?
      user.notes.create!(reason: "banned", content: "spam account")
    end
    user.comments.each do |comment|
      comment.reactions.each &:destroy!
      comment.destroy!
    end
    user.articles.each &:destroy!
    user.remove_from_index!
    user.save!
    user.update!(old_username: nil)
  rescue => e
    flash[:error] = e.message
  end
end
