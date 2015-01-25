require 'rejbca'
class Api::EndEntitiesController < ApplicationController

  def create
    
    
    @app = current_user.apps.find_by_uuid(params[:app_id])
    
    
    @end_entity = EndEntity.new
    @end_entity.did = params[:did]
    @end_entity.app_id = @app.id

    if @end_entity.save
      
      rejbca = Rejbca.instance
      
      user_attributes = { 'username' => @end_entity.uuid, 'password' => @end_entity.e_password, 'subjectDN' => "CN=#{@end_entity.uuid},OU=#{@app.name},OU=Cloud Sec,L=London,C=GB" }
      result = rejbca.add_user(user_attributes)
      

      render json: {entity_uuid: @end_entity.uuid, entity_password: @end_entity.e_password}
      
    else
      render json: {error: true}
    end
  end

end