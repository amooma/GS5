class GatewaySettingsController < ApplicationController
  load_and_authorize_resource :gateway
  load_and_authorize_resource :gateway_setting, :through => [:gateway]

  def index
    @gateway_settings = @gateway.gateway_settings
  end

  def show
  end

  def new
   # @gateway_setting = @gateway.gateway_settings.build
  end

  def create
    @gateway_setting = @gateway.gateway_settings.build(params[:gateway_setting])
    if @gateway_setting.save
      redirect_to [@gateway, @gateway_setting], :notice => t('gateway_settings.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @gateway_setting = @gateway.gateway_settings.find(params[:id])
  end

  def update
    @gateway_setting = @gateway.gateway_settings.find(params[:id])
    if @gateway_setting.update_attributes(params[:gateway_setting])
      redirect_to [@gateway, @gateway_setting], :notice  => t('gateway_settings.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @gateway_setting = @gateway.gateway_settings.find(params[:id])
    @gateway_setting.destroy
    redirect_to gateway_gateway_settings_path(@gateway), :notice => t('gateway_settings.controller.successfuly_destroyed')
  end
end
