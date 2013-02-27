class CallsController < ApplicationController
  load_resource :sip_account
  load_resource :call

  before_filter :set_and_authorize_parent
  
  def index
    if @parent
      @calls = @parent.calls
    else
      @calls = Call.all
    end
  end

  def new
    if !params[:url].blank?
      protocol, separator, phone_number = params[:url].partition(':')
      if ! phone_number.blank? 
        @call = @parent.calls.new()
        @call.dest = phone_number
      end
    elsif !params[:number].blank?
      @call = @parent.calls.new()
      @call.dest = params[:number]
    end
  end

  def show
    redirect_to :index
  end

  def create
    params[:call][:sip_account] = @sip_account
    @call = Call.create(params[:call])

    if @call && @call.call
      m = method( :"#{@parent.class.name.underscore}_calls_url" )
      redirect_to m.( @parent ), :notice => t('calls.controller.successfuly_created')
    else
      render :new
    end
  end

  def destroy
    @call.destroy
    if @parent
      m = method( :"#{@parent.class.name.underscore}_calls_url" )
    else
      m = method( :"calls_url" )
    end
    redirect_to m.(@parent), :notice => t('calls.controller.successfuly_destroyed')
  end

  private
  def set_and_authorize_parent
    @parent = @sip_account
  end
end
