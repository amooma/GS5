class GsParametersController < ApplicationController
  def index
    @gs_parameters = GsParameter.order([:section, :name])
    @sections = @gs_parameters.pluck(:section).uniq.sort
  end

  def show
    @gs_parameter = GsParameter.find(params[:id])
  end

  def new
    @gs_parameter = GsParameter.new
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
end
