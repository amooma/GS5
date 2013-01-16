class RouteElementsController < ApplicationController
  load_and_authorize_resource :call_route
  load_and_authorize_resource :route_element, :through => [:call_route]
  
  before_filter :spread_breadcrumbs

  def index
    @route_elements = @call_route.route_elements
  end

  def show
    @route_element = @call_route.route_elements.find(params[:id])
  end

  def new
    @route_element = @call_route.route_elements.build
  end

  def create
    @route_element = @call_route.route_elements.build(params[:route_element])
    if @route_element.save
      redirect_to [@call_route, @route_element], :notice => t('route_elements.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @route_element = @call_route.route_elements.find(params[:id])
  end

  def update
    @route_element = @call_route.route_elements.find(params[:id])
    if @route_element.update_attributes(params[:route_element])
      redirect_to [@call_route, @route_element], :notice  => t('route_elements.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @route_element = @call_route.route_elements.find(params[:id])
    @route_element.destroy
    redirect_to call_route_route_elements_path(@call_route), :notice => t('route_elements.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    add_breadcrumb t("call_routes.index.page_title"), call_routes_path
    add_breadcrumb @call_route, call_route_path(@call_route)
    add_breadcrumb t("route_elements.index.page_title"), call_route_route_elements_path(@call_route)
    if @route_element && !@route_element.new_record?
      add_breadcrumb @route_element, call_route_route_element_path(@call_route, @route_element)
    end
  end

end
