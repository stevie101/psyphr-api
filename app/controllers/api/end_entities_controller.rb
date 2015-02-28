class Api::EndEntitiesController < ApplicationController

  def create
        
    @end_entity = EndEntity.new(end_entity_params)
    @app = SecApp.find_by_uuid(params[:end_entity][:sec_app_id])
    @end_entity.sec_app_id = @app.id
    @end_entity.save

    render json: {uuid: @end_entity.uuid}, status: 200 and return

  end

  def end_entity_params
    params.require(:end_entity).permit(:sec_app_id, :did)
  end

end