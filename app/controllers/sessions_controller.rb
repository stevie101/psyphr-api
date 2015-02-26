class SessionsController < ApplicationController

  # User login view
  def new
    user = User.find_by_email(params[:email])
    if user and user.password_digest.present? and user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_url, :notice => "Logged in!"
    else
      flash.now.alert = "Invalid email or password"
      render "new"
    end
  end

  # User login action
  def create
    
    user = User.find_by_email(params[:email])
    
    if user and user.password_digest.present? and user.authenticate(params[:password])
      session[:user_id] = user.id
      if session[:return_to]
        redirect_to session[:return_to], :notice => "Logged in!"
      else
        redirect_to admin_apps_path, :notice => "Logged in!"
      end
    else
      redirect_to login_url, alert: "Invalid email or password"
    end
  
  end
  
  # User logout action
  def destroy
    session[:user_id] = nil
    redirect_to root_url, :notice => "Logged out!"
  end

end
