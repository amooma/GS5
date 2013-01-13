class GatewaysController < ApplicationController
  def index
    @gateways = Gateway.all
  end

  def show
    @gateway = Gateway.find(params[:id])
  end

  def new
    @gateway = Gateway.new
  end

  def create
    @gateway = Gateway.new(params[:gateway])
    if @gateway.save
      redirect_to @gateway, :notice => t('gateways.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @gateway = Gateway.find(params[:id])
  end

  def update
    @gateway = Gateway.find(params[:id])
    if @gateway.update_attributes(params[:gateway])
      redirect_to @gateway, :notice  => t('gateways.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @gateway = Gateway.find(params[:id])
    @gateway.destroy
    redirect_to gateways_url, :notice => t('gateways.controller.successfuly_destroyed')
  end
end
