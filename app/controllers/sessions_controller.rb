class SessionsController < Devise::SessionsController
  def destroy
    # Let's say goodbye to all the cookies when someone signs out.
    cookies.each do |cookie|
      cookies.delete cookie[0]
    end
    super
  end
end
