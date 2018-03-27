class DigestMailer < ApplicationMailer
  def daily_digest(recipient)
    @recipient = recipient
  end
end
