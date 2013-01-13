class GatewayParametersController < ApplicationController
  def index
    @gateway_parameters = GatewayParameter.all
  end

  def show
    @gateway_parameter = GatewayParameter.find(params[:id])
  end

  def new
    @gateway_parameter = GatewayParameter.new
  end

  def create
    @gateway_parameter = GatewayParameter.new(params[:gateway_parameter])
    if @gateway_parameter.save
      redirect_to @gateway_parameter, :notice => t('gateway_parameters.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @gateway_parameter = GatewayParameter.find(params[:id])
  end

  def update
    @gateway_parameter = GatewayParameter.find(params[:id])
    if @gateway_parameter.update_attributes(params[:gateway_parameter])
      redirect_to @gateway_parameter, :notice  => t('gateway_parameters.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @gateway_parameter = GatewayParameter.find(params[:id])
    @gateway_parameter.destroy
    redirect_to gateway_parameters_url, :notice => t('gateway_parameters.controller.successfuly_destroyed')
  end
end
