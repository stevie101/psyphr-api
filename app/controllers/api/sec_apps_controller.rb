class Api::SecAppsController < ApplicationController
  
  before_filter :require_app
  
  def crl
    
  end
  
  def require_app
    
    @app = SecApp.find_by_uuid(params[:id])
    
    unless @app
    
      render json: {error: true, message: 'Invalid app'} and return
    
    end
    
  end
  
end
