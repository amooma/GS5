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
    if @gs_parameter.update_attributes(gs_parameter_params)
      redirect_to @gs_parameter, :notice  => t('gs_parameters.controller.successfuly_updated')
    else
      render :edit
    end
  end

  private
  def gs_parameter_params
    params.require(:gs_parameter).permit(:value, :class_type, :description)
  end
end
