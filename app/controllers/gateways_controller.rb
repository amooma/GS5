class GatewaysController < ApplicationController
  authorize_resource :gateway

  def index
    @gateways = Gateway.all
    spread_breadcrumbs
  end

  def show
    @gateway = Gateway.find(params[:id])
    spread_breadcrumbs
  end

  def new
    @gateway = Gateway.new
    @technologies = Gateway::TECHNOLOGIES
    spread_breadcrumbs
  end

  def create
    @gateway = Gateway.new(params[:gateway])
    spread_breadcrumbs
    if @gateway.save
      redirect_to @gateway, :notice => t('gateways.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @gateway = Gateway.find(params[:id])
    @technologies = Gateway::TECHNOLOGIES
    spread_breadcrumbs
  end

  def update
    @gateway = Gateway.find(params[:id])
    spread_breadcrumbs
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

  private
  def spread_breadcrumbs
    add_breadcrumb t("gateways.index.page_title"), gateways_path
    if @gateway && !@gateway.new_record?
      add_breadcrumb @gateway, @gateway
    end
  end  
end
