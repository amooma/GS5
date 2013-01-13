class GatewayParametersController < ApplicationController
  load_and_authorize_resource :gateway
  load_and_authorize_resource :gateway_parameter, :through => [:gateway]

  def index
    @gateway_parameters = @gateway.gateway_parameters
  end

  def show
    @gateway_parameter = @gateway.gateway_parameters.find(params[:id])
  end

  def new
    @gateway_parameter = @gateway.gateway_parameters.build
  end

  def create
    @gateway_parameter = @gateway.gateway_parameters.build(params[:gateway_parameter])
    if @gateway_parameter.save
      redirect_to @gateway, :notice => t('gateway_parameters.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @gateway_parameter = @gateway.gateway_parameters.find(params[:id])
  end

  def update
    @gateway_parameter = @gateway.gateway_parameters.find(params[:id])
    if @gateway_parameter.update_attributes(params[:gateway_parameter])
      redirect_to @gateway, :notice  => t('gateway_parameters.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @gateway_parameter = @gateway.gateway_parameters.find(params[:id])
    @gateway_parameter.destroy
    redirect_to gateway_path(@gateway), :notice => t('gateway_parameters.controller.successfuly_destroyed')
  end
end
