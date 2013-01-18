class GsParametersController < ApplicationController
  load_resource :gs_parameter

  before_filter :spread_breadcrumbs

  def index
    @gs_parameters_unordered = GsParameter.scoped
    @gs_parameters = GsParameter.order([:section, :name])
    @sections = @gs_parameters.pluck(:section).uniq.sort
  end

  def show
    @gs_parameter = GsParameter.find(gs_parameter_params[:id])
  end

  def new
    @gs_parameter = GsParameter.new
  end

  def edit
    @gs_parameter = GsParameter.find(gs_parameter_params[:id])
  end

  def update
    @gs_parameter = GsParameter.find(gs_parameter_params[:id])
    if @gs_parameter.update_attributes(gs_parameter_params)
      redirect_to @gs_parameter, :notice  => t('gs_parameters.controller.successfuly_updated')
    else
      render :edit
    end
  end

  private
  def gs_parameter_params
    params.require(:gs_parameter).permit(:id, :value, :class_type, :description)
  end

  def spread_breadcrumbs
    add_breadcrumb t("gs_parameters.index.page_title"), gs_parameters_path
    if @gs_parameter && !@gs_parameter.new_record?
      add_breadcrumb @gs_parameter, gs_parameter_path(@gs_parameter)
    end
  end
end
