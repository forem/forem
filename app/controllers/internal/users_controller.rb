module Internal
  class UsersController < ApplicationController
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
      @user = if params[:id] == "unmatched_mentee"
                MentorRelationship.unmatched_mentees.order("RANDOM()").first
              else
                User.find(params[:id])
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
      if user_params[:quick_match]
        redirect_to "/internal/users/unmatched_mentee"
      else
        redirect_to "/internal/users/#{params[:id]}"
      end
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
      begin
        Moderator::Banisher.call(admin: current_user, offender: @user)
      rescue StandardError => e
        flash[:error] = e.message
      end
      redirect_to "/internal/users/#{@user.id}/edit"
    end

    private

    def user_params
      params.require(:user).permit(:seeking_mentorship,
                                  :offering_mentorship,
                                  :add_mentor,
                                  :quick_match,
                                  :add_mentee,
                                  :mentorship_note,
                                  :ban_from_mentorship)
    end
  end
end
