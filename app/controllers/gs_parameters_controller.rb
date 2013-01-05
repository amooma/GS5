class GsParametersController < ApplicationController
  def index
    @gs_parameters = GsParameter.all
  end

  def show
    @gs_parameter = GsParameter.find(params[:id])
  end

  def new
    @gs_parameter = GsParameter.new
  end

  def create
    @gs_parameter = GsParameter.new(params[:gs_parameter])
    if @gs_parameter.save
      redirect_to @gs_parameter, :notice => t('gs_parameters.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @gs_parameter = GsParameter.find(params[:id])
  end

  def update
    @gs_parameter = GsParameter.find(params[:id])
    if @gs_parameter.update_attributes(params[:gs_parameter])
      redirect_to @gs_parameter, :notice  => t('gs_parameters.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @gs_parameter = GsParameter.find(params[:id])
    @gs_parameter.destroy
    redirect_to gs_parameters_url, :notice => t('gs_parameters.controller.successfuly_destroyed')
  end
end
