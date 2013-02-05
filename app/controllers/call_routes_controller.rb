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

    logger.error "ENDPOINT TYPE: #{params[:call_route][:endpoint_type]}"
    logger.error "ENDPOINT ID: #{params[:call_route][:endpoint_id]}"
    logger.error "ENDPOINT STR: #{params[:call_route][:endpoint_str]}"

    if @call_route.update_attributes(call_route_parameter_params)
      logger.error "CALL_ROUTE: #{@call_route.inspect}"
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

  def show_variables
    @channel_variables = Hash.new()
    file_name = '/var/log/freeswitch/variables'
    if File.readable?(file_name)
      File.readlines(file_name).each do |line|
        key, delimeter, value = line.partition(': ')
        key = to_channel_variable_name(key)
        if !key.blank?
          @channel_variables[key] = URI.unescape(value.gsub(/\n/, ''));
        end
      end
    end
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

  def to_channel_variable_name(name)
    variables_map = {
      'Channel-State' => 'state',
      'Channel-State-Number' => 'state_number',
      'Channel-Name' => 'channel_name',
      'Unique-ID' => 'uuid',
      'Call-Direction' => 'direction',
      'Answer-State' => 'state',
      'Channel-Read-Codec-Name' => 'read_codec',
      'Channel-Read-Codec-Rate' => 'read_rate',
      'Channel-Write-Codec-Name' => 'write_codec',
      'Channel-Write-Codec-Rate' => 'write_rate',
      'Caller-Username' => 'username',
      'Caller-Dialplan' => 'dialplan',
      'Caller-Caller-ID-Name' => 'caller_id_name',
      'Caller-Caller-ID-Number' => 'caller_id_number',
      'Caller-ANI' => 'ani',
      'Caller-ANI-II' => 'aniii',
      'Caller-Network-Addr' => 'network_addr',
      'Caller-Destination-Number' => 'destination_number',
      'Caller-Unique-ID' => 'uuid',
      'Caller-Source' => 'source',
      'Caller-Context' => 'context',
      'Caller-RDNIS' => 'rdnis',
      'Caller-Channel-Name' => 'channel_name',
      'Caller-Profile-Index' => 'profile_index',
      'Caller-Channel-Created-Time' => 'created_time',
      'Caller-Channel-Answered-Time' => 'answered_time',
      'Caller-Channel-Hangup-Time' => 'hangup_time',
      'Caller-Channel-Transfer-Time' => 'transfer_time',
      'Caller-Screen-Bit' => 'screen_bit',
      'Caller-Privacy-Hide-Name' => 'privacy_hide_name',
      'Caller-Privacy-Hide-Number' => 'privacy_hide_number',
    }

    name = name.gsub(/[^a-zA-Z1-9_\-]/, '')

    if variables_map[name]
      return variables_map[name]
    elsif name.match(/^variable_/)
      return name.gsub(/^variable_/, '')
    end

    return nil
  end

end
