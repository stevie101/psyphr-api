class Admin::EndEntities::CertificatesController < ApplicationController
  
  before_filter :require_user
  before_filter :require_end_entity

  def index
    @certificates = @end_entity.certificates
  end
  
  def new
    @certificate = Certificate.new
  end
  
  def create
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

  def revoke
    
    cert = @end_entity.certificates.find(params[:certificate_id])
    
    cert.update_attributes( status: 'R', revoked_at: Time.now)
    
    redirect_to admin_end_entity_url(@end_entity)
  end

private

  def certificate_params
    params.require(:certificate).permit(:user_id, :common_name, :organisational_unit, :organisation, :locality, :state, :country)
  end

  def require_end_entity
    @end_entity = @current_user.end_entities.find(params[:end_entity_id])
  end

end
