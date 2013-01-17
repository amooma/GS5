class CallRoutesController < ApplicationController
  load_and_authorize_resource :call_route
  
  before_filter :spread_breadcrumbs

  def index
    @call_routes = CallRoute.order(['`table`', :position])
    @tables = @call_routes.pluck('`table`').uniq.sort
  end

  def show
  end

  def new
  end

  def create
    @call_route = CallRoute.new(params[:call_route])
    if @call_route.save
      redirect_to @call_route, :notice => t('call_routes.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @call_route.update_attributes(params[:call_route])
      redirect_to @call_route, :notice  => t('call_routes.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @call_route.destroy
    redirect_to call_routes_url, :notice => t('call_routes.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    add_breadcrumb t("call_routes.index.page_title"), call_routes_path
    if @call_route && !@call_route.new_record?
      add_breadcrumb @call_route, call_route_path(@call_route)
    end
  end

end
