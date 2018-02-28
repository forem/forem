class FeedbackMessagesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    flash.clear
    @feedback = FeedbackMessage.new(feedback_message_params.merge(user_id: current_user&.id))
    if authorize_send?
      send_slack_message
      @feedback.save
      render :index
    elsif feedback_message_params[:feedback_type] == "bug-reports"
      flash.now[:notice] = "Make sure the forms are filled 🤖 "
      render file: "public/500.html", status: 500, layout: false
    else
      flash.now[:notice] = "Make sure the forms are filled 🤖 "
      @previous_message = feedback_message_params[:message]
      render "pages/report-abuse.html.erb"
    end
  end

  def authorize_send?
    recaptcha_verified? && form_filled?
  end

  private

  def recaptcha_verified?
    params["g-recaptcha-response"] && verify_recaptcha(secret_key: ENV["RECAPTCHA_SECRET"])
  end

  def send_slack_message
    SlackBot.ping(
      generate_message,
      channel: "#{feedback_message_params[:feedback_type]}",
      username: "#{feedback_message_params[:feedback_type]}_bot",
      icon_emoji: ":#{emoji_for_feedback(feedback_message_params[:feedback_type])}:",
    )
  end

  def generate_message
    <<~HEREDOC
      #{generate_user_detail}
      Category: #{feedback_message_params[:category_selection]}
      Message: #{feedback_message_params[:message]}
      URL: #{params[:url]}
    HEREDOC
  end

  def generate_user_detail
    return "" unless current_user
    <<~HEREDOC
      *Logged in user:*
      username: #{current_user.username}
      email: #{current_user.email}
      twitter: #{current_user.twitter_username}
      github: #{current_user.github_username}
    HEREDOC
  end

  def form_filled?
    if feedback_message_params[:feedback_type] == "abuse-reports"
      feedback_message_params[:category_selection].present?
    else
      feedback_message_params[:message].present? ||
        feedback_message_params[:category_selection].present?
    end
  end

  def emoji_for_feedback(feedback_type)
    case feedback_type
    when "abuse-reports"
      "cry"
    when "bug-reports"
      "face_with_head_bandage"
    else
      "robot_face"
    end
  end

  def feedback_message_params
    params[:feedback_message].permit(:message, :feedback_type, :category_selection)
  end
end
