class CallRoutesController < ApplicationController
  authorize_resource :call_route, :except => [:sort]

  before_filter { |controller|
    if !params[:call_route].blank? && !params[:call_route][:endpoint_str].blank?
      params[:call_route][:endpoint_type], delimeter, params[:call_route][:endpoint_id] = params[:call_route][:endpoint_str].partition('=')
    end
  }

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
    @endpoints = Gateway.all.collect {|r| [ "gateway: #{r.to_s}", "gateway=#{r.id}" ] }
    @endpoints << [ 'phonenumber', 'phonenumber=' ]
    @endpoints << [ 'dialplanfunction', 'dialplanfunction=' ]
    @endpoints << [ 'hangup', 'hangup=' ]
    @endpoints << [ 'unknown', 'unknown=' ]
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
    @endpoints = Gateway.all.collect {|r| [ "gateway: #{r.to_s}", "gateway=#{r.id}" ] }
    @endpoints << [ 'phonenumber', 'phonenumber=' ]
    @endpoints << [ 'dialplanfunction', 'dialplanfunction=' ]
    @endpoints << [ 'hangup', 'hangup=' ]
    @endpoints << [ 'unknown', 'unknown=' ]
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

  def sort
    params[:call_route].each_with_index do |id, index|
      CallRoute.update_all({position: index+1}, {id: id})
      #CallRoute.find(:id).move_to_bottom
    end
    render nothing: true
  end

  private
  def call_route_parameter_params
    params.require(:call_route).permit(:routing_table, :name, :endpoint_type, :endpoint_id, :position)
  end

  def spread_breadcrumbs
    add_breadcrumb t("call_routes.index.page_title"), call_routes_path
    if @call_route && !@call_route.new_record?
      add_breadcrumb @call_route, @call_route
    end
  end

end
