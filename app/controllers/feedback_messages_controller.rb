class FeedbackMessagesController < ApplicationController
  # No authorization required for entirely public controller
  skip_before_action :verify_authenticity_token

  def create
    flash.clear
    @feedback_message = FeedbackMessage.new(
      feedback_message_params.merge(reporter_id: current_user&.id),
    )
    if recaptcha_verified? && @feedback_message.save
      send_slack_message
      redirect_to "/feedback_messages"
    else
      flash[:notice] = "Make sure the forms are filled 🤖 "
      @previous_message = feedback_message_params[:message]
      render "pages/report-abuse.html.erb"
    end
  end

  private

  def recaptcha_verified?
    params["g-recaptcha-response"] &&
      verify_recaptcha(secret_key: ApplicationConfig["RECAPTCHA_SECRET"])
  end

  def send_slack_message
    SlackBot.ping(
      generate_message,
      channel: feedback_message_params[:feedback_type],
      username: "#{feedback_message_params[:feedback_type]}_bot",
      icon_emoji: ":#{emoji_for_feedback(feedback_message_params[:feedback_type])}:",
    )
  end

  def generate_message
    <<~HEREDOC
      #{generate_user_detail}
      Category: #{feedback_message_params[:category]}
      Internal Report: https://dev.to/internal/reports
      *_ Reported URL: #{feedback_message_params[:reported_url]} _*
      -----
      *Message:* #{feedback_message_params[:message]}
    HEREDOC
  end

  def generate_user_detail
    return "*Anonymous report:*" unless current_user

    <<~HEREDOC
      *Logged in user:*
      reporter: #{current_user.username} - https://dev.to/#{current_user.username}
      email: <mailto:#{current_user.email}|#{current_user.email}>
    HEREDOC
  end

  def emoji_for_feedback(feedback_type)
    case feedback_type
    when "abuse-reports"
      "cry"
    else
      "robot_face"
    end
  end

  def feedback_message_params
    params[:feedback_message].permit(:message, :feedback_type, :category, :reported_url)
  end
end
