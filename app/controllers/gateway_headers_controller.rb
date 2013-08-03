class GatewayHeadersController < ApplicationController
  load_and_authorize_resource :gateway
  load_and_authorize_resource :gateway_header, :through => [:gateway]

  before_filter :spread_breadcrumbs

  def index
    @gateway_headers = @gateway.gateway_headers
  end

  def show
    @gateway_header = @gateway.gateway_headers.find(params[:id])
  end

  def new
    @gateway_header = @gateway.gateway_headers.build
  end

  def create
    @gateway_header = @gateway.gateway_headers.build(params[:gateway_header])
    if @gateway_header.save
      redirect_to @gateway, :notice => t('gateway_headers.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @gateway_header = @gateway.gateway_headers.find(params[:id])
  end

  def update
    @gateway_header = @gateway.gateway_headers.find(params[:id])
    if @gateway_header.update_attributes(params[:gateway_header])
      redirect_to @gateway, :notice  => t('gateway_headers.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @gateway_header = @gateway.gateway_headers.find(params[:id])
    @gateway_header.destroy
    redirect_to gateway_path(@gateway), :notice => t('gateway_headers.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    add_breadcrumb t("gateways.index.page_title"), gateways_path
    add_breadcrumb @gateway, @gateway
    add_breadcrumb t("gateway_headers.index.page_title"), gateway_gateway_headers_url(@gateway)

    if @gateway_header && !@gateway_header.new_record?
      add_breadcrumb @gateway_header
    end
  end
end
