require 'rejbca'
class Admin::EndEntitiesController < ApplicationController

  before_filter :require_user

  def index
    
    @end_entities = @current_user.end_entities
    
  end
  
  def new
    
    @apps = @current_user.apps
    @end_entity = EndEntity.new
    
  end
  
  def create
    
    @end_entity = EndEntity.new(end_entity_params)
    
    @app = current_user.apps.find(params[:app][:id])
    
    @end_entity.app_id = @app.id

    if @end_entity.save
      
      rejbca = Rejbca.instance
      
      user_attributes = { 'username' => @end_entity.uuid, 'password' => @end_entity.e_password, 'subjectDN' => "CN=#{@end_entity.uuid},OU=#{@app.name},OU=Cloud Sec,L=London,C=GB" }
      result = rejbca.add_user(user_attributes)
      

      
      redirect_to :admin_end_entities
    else
      render :new
    end
    
  end
  
  def edit
    
  end

  def update
    
  end

  def destroy
    
  end
  
  def show
    
    @end_entity = @current_user.end_entities.find(params[:id])
    
  rescue
    render text: 'End entity not found'
  end

  def end_entity_params
    params.require(:end_entity).permit(:app_id, :did)
  end

  def enrol
    
    @end_entity = @current_user.end_entities.find(params[:end_entity_id])
    @app = current_user.apps.find(@end_entity.app_id)
    
    rejbca = Rejbca.instance
    
    user_attribs = { 'username' => @end_entity.uuid, 'password' => @end_entity.e_password , 'subjectDN' => "CN=#{@end_entity.uuid},OU=#{@app.name},OU=Cloud Sec,L=London,C=GB" }
    certificate = rejbca.enrol(user_attribs, params[:csr])
    
    if certificate
    
      @end_entity.update_attributes( cert: certificate, status: 2 )
      
    
    end
    
    redirect_to admin_end_entity_url(@end_entity)
  end

end
