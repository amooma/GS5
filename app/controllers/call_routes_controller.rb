class CallRoutesController < ApplicationController
  def index
    @call_routes = CallRoute.all
  end

  def show
    @call_route = CallRoute.find(params[:id])
  end

  def new
    @call_route = CallRoute.new
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
    @call_route = CallRoute.find(params[:id])
  end

  def update
    @call_route = CallRoute.find(params[:id])
    if @call_route.update_attributes(params[:call_route])
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
end
