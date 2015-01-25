class Admin::EndEntities::CertificatesController < ApplicationController
  
  before_filter :require_user

  def index
    @end_entity = @current_user.end_entities.find(params[:end_entity_id])
    @certificates = @end_entity.certificates
  end
  
  def new
    @end_entity = @current_user.end_entities.find(params[:end_entity_id])
    @certificate = Certificate.new
  end
  
  def create
    @end_entity = @current_user.end_entities.find(params[:end_entity_id])
    @certificate = Certificate.new(certificate_params)
    @certificate.end_entity_id = params[:end_entity_id]

    if @certificate.save
      redirect_to admin_end_entity_url(@end_entity)
    else
      render :new
    end
  end

  def show
    
  end

  def certificate_params
    params.require(:certificate).permit(:user_id, :common_name, :organisational_unit, :organisation, :locality, :state, :country)
  end

end
