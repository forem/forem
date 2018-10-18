class Internal::UsersController < Internal::ApplicationController
  layout "internal"

  def index
    @users = case params[:state]
             when "mentors"
               User.where(offering_mentorship: true).page(params[:page]).per(20)
             when "mentees"
               User.where(seeking_mentorship: true).page(params[:page]).per(20)
             else
               User.order("created_at DESC").page(params[:page]).per(20)
             end
  end

  def edit
    @user = User.find(params[:id])
  end

  def show
    if params[:id] == "unmatched_mentee"
      @user = MentorRelationship.unmatched_mentees.order("RANDOM()").first
    else
      @user = User.find(params[:id])
    end
    @user_mentee_relationships = MentorRelationship.where(mentor_id: @user.id)
    @user_mentor_relationships = MentorRelationship.where(mentee_id: @user.id)
  end

  def update
    @user = User.find(params[:id])
    @new_mentee = user_params[:add_mentee]
    @new_mentor = user_params[:add_mentor]
    handle_mentorship
    add_note
    @user.update!(user_params)
    redirect_to "/internal/users/unmatched_mentee"
  end

  def handle_mentorship
    if user_params[:ban_from_mentorship] == "1"
      ban_from_mentorship
    end

    if @new_mentee.blank? && @new_mentor.blank?
      return
    end
    make_matches
  end

  def make_matches
    if !@new_mentee.blank?
      mentee = User.find(@new_mentee)
      MentorRelationship.new(mentee_id: mentee.id, mentor_id: @user.id).save!
    end

    if !@new_mentor.blank?
      mentor = User.find(@new_mentor)
      MentorRelationship.new(mentee_id: @user.id, mentor_id: mentor.id).save!
    end
  end

  def add_note
    if user_params[:mentorship_note]
      Note.create(
        author_id: @current_user.id,
        noteable_id: @user.id,
        noteable_type: "User",
        reason: "mentorship",
        content: user_params[:mentorship_note],
      )
    end
  end

  def inactive_mentorship(mentor, mentee)
    relationship = MentorRelationship.where(mentor_id: mentor.id, mentee_id: mentee.id)
    relationship.update(active: false)
  end

  def ban_from_mentorship
    @user.add_role :banned_from_mentorship
    mentee_relationships = MentorRelationship.where(mentor_id: @user.id)
    mentor_relationships = MentorRelationship.where(mentee_id: @user.id)
    deactivate_mentorship(mentee_relationships)
    deactivate_mentorship(mentor_relationships)
  end

  def deactivate_mentorship(relationships)
    relationships.each do |relationship|
      relationship.update(active: false)
    end
  end

  def banish
    @user = User.find(params[:id])
    banish_user(@user)
    redirect_to "/internal/users/#{@user.id}/edit"
  end

  def banish_user(user)
    set_banned_attributes(user)
    user.comments.each do |comment|
      comment.reactions.each { |rxn| rxn.delay.destroy! }
      comment.delay.destroy!
    end
    user.articles.each { |article| article.delay.destroy! }
    ban_and_obscure(user)
  rescue StandardError => e
    flash[:error] = e.message
  end

  private

  def set_banned_attributes(user)
    new_name = "spam_#{rand(10000)}"
    new_username = "spam_#{rand(10000)}"
    if User.find_by(name: new_name) || User.find_by(username: new_username)
      new_name = "spam_#{rand(10000)}"
      new_username = "spam_#{rand(10000)}"
    end
    new_attributes = {
      name: new_name,
      username: new_username,
      twitter_username: "",
      github_username: "",
      website_url: "",
      summary: "",
      location: "",
      education: "",
      employer_name: "",
      employer_url: "",
      employment_title: "",
      mostly_work_with: "",
      currently_learning: "",
      currently_hacking_on: "",
      available_for: "",
      email_public: false,
      facebook_url: nil,
      dribbble_url: nil,
      stackoverflow_url: nil,
      behance_url: nil,
      linkedin_url: nil
    }
    user.attributes = new_attributes
    user.remote_profile_image_url = "https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png"
  end

  def ban_and_obscure(user)
    user.save!
    user.add_role :banned
    user.notes.create(reason: "banned", content: "spam account", author_id: current_user.id)
    user.remove_from_algolia_index
    CacheBuster.new.bust("/#{user.old_username}")
    user.update!(old_username: nil)
  end

  def user_params
    params.require(:user).permit(:seeking_mentorship,
                                 :offering_mentorship,
                                 :add_mentor,
                                 :add_mentee,
                                 :mentorship_note,
                                 :ban_from_mentorship)
  end
end
