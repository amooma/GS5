class CallRoutesController < ApplicationController
  authorize_resource :call_route

  def index
    @call_routes = CallRoute.order([:routing_table, :position])
    @routing_tables = @call_routes.pluck(:routing_table).uniq.sort
    spread_breadcrumbs
  end

  def show
    @call_route = CallRoute.find(params[:id])
    spread_breadcrumbs
  end

  def new
    @call_route = CallRoute.new
    spread_breadcrumbs
  end

  def create
    @call_route = CallRoute.new(call_route_parameter_params)
    spread_breadcrumbs
    if @call_route.save
      redirect_to @call_route, :notice => t('call_routes.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @call_route = CallRoute.find(params[:id])
    spread_breadcrumbs
  end

  def update
    @call_route = CallRoute.find(params[:id])
    spread_breadcrumbs
    if @call_route.update_attributes(call_route_parameter_params)
      redirect_to @call_route, :notice  => t('call_routes.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @call_route = CallRoute.find(params[:id])
    @call_route.destroy
    redirect_to call_routes_url, :notice => t('call_routes.controller.successfuly_destroyed')
  end

  def move_higher
    @call_route = CallRoute.find(params[:id])
    @call_route.move_higher
    redirect_to :back
  end

  def move_lower
    @call_route = CallRoute.find(params[:id])
    @call_route.move_lower
    redirect_to :back
  end

  private
  def call_route_parameter_params
    params.require(:call_route).permit(:routing_table, :name, :endpoint_type, :endpoint_id)
  end

  def spread_breadcrumbs
    add_breadcrumb t("call_routes.index.page_title"), call_routes_path
    if @call_route && !@call_route.new_record?
      add_breadcrumb @call_route, @call_route
    end
  end

end