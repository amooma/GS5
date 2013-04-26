class GatewayParametersController < ApplicationController
  load_and_authorize_resource :gateway
  load_and_authorize_resource :gateway_parameter, :through => [:gateway]

  before_filter :spread_breadcrumbs

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

  private
  def spread_breadcrumbs
    add_breadcrumb t("gateways.index.page_title"), gateways_path
    add_breadcrumb @gateway, @gateway
    add_breadcrumb t("gateway_parameters.index.page_title"), gateway_gateway_parameters_url(@gateway)

    if @gateway_parameter && !@gateway_parameter.new_record?
      add_breadcrumb @gateway_parameter
    end
  end
end
