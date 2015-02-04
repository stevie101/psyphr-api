class SessionsController < ApplicationController

  # User login view
  def new
    
  end

  # User login action
  def create
    redirect_to admin_apps_path
  end
  
  # User logout action
  def destroy
    render text: "You've logged out" and return
  end

end
