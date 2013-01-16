class RouteElementsController < ApplicationController
  def index
    @route_elements = RouteElement.all
  end

  def show
    @route_element = RouteElement.find(params[:id])
  end

  def new
    @route_element = RouteElement.new
  end

  def create
    @route_element = RouteElement.new(params[:route_element])
    if @route_element.save
      redirect_to @route_element, :notice => t('route_elements.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @route_element = RouteElement.find(params[:id])
  end

  def update
    @route_element = RouteElement.find(params[:id])
    if @route_element.update_attributes(params[:route_element])
      redirect_to @route_element, :notice  => t('route_elements.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @route_element = RouteElement.find(params[:id])
    @route_element.destroy
    redirect_to route_elements_url, :notice => t('route_elements.controller.successfuly_destroyed')
  end
end
