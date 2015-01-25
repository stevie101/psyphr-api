class Api::EndEntities::CertificatesController < ApplicationController
  def update
    @end_entity = EndEntity.find_by_uuid(params[:uuid])
    if @end_entity.update_attributes(cert: params[:certificate])
      render json: {result: 'success'}
    else
      render json: {error: true}
    end
  end
  
  def show
    
    # Device requesting an EE cert needs to sign the request and send it's uuid so that 
    # the server can verify the request is from a valid device associated with the user's app
    
    # curl -X GET -H "Content-Type: application/json" -d '{"app_id" : "08346872-8311-11e4-9353-70cd60fffe0e", "did" : "foobar1", "device_uuid": "xxxx"}' http://127.0.0.1:3000/api/end_entities/80322ed4-8435-11e4-bc21-70cd60fffe0e/certificate
    
    @end_entity = EndEntity.find_by_uuid(params[:end_entity_id])
    render json: {certificate: @end_entity.cert}
  rescue
    render json: {error: true}
  end
end
