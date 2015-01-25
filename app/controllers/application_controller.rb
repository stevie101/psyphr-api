class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception
  protect_from_forgery with: :null_session

  def current_user
    # @current_user ||= User.find(session[:user_id]) if session[:user_id]
    @current_user = User.first            # Until the user authentication is added
  end
  helper_method :current_user
  
  def user_signed_in?
    !!current_user
  end
  helper_method :user_signed_in?
  
  def require_user
    unless user_signed_in?
      flash[:alert] = "You need to be logged in to access that page."
      redirect_to login_url
    end
  end

end
