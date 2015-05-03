class Api::EndEntitiesController < ApplicationController

  before_action :doorkeeper_authorize!

  def create
        
    # Get app for the given app uuid
    @app = SecApp.find_by_uuid(params[:end_entity][:sec_app_id])   
    
    if @app

      # Check if an entity already exists for this app
      @end_entity = @app.end_entities.find_by_did(params[:end_entity][:did])
      
      if not @end_entity
        
        @end_entity = EndEntity.new(end_entity_params)
        @end_entity.sec_app_id = @app.id
        @end_entity.save
        
        render json: {uuid: @end_entity.uuid, e_password: @end_entity.password}, status: 200 and return
        
      else
      
        render json: {error: true, message: 'Entity already exists'}, status: 400 and return
      
      end
    
    else
      
      render json: {error: true, message: 'Invalid app uuid'}, status: 403 and return
    
    end

  end

  def end_entity_params
    params.require(:end_entity).permit(:sec_app_id, :did)
  end

end