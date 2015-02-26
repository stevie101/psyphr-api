class Api::EndEntitiesController < ApplicationController

  def create
        
    @end_entity = EndEntity.new(end_entity_params)
    @app = App.find_by_uuid(params[:app][:uuid])
    @end_entity.app_id = @app.id
    @end_entity.save

    render text: '', status: 200 and return

  end

  def end_entity_params
    params.require(:end_entity).permit(:app_id, :did)
  end

end