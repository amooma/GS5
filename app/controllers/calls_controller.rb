class CallsController < ApplicationController
  load_resource :sip_account
  load_resource :call

  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs
  
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

  def spread_breadcrumbs
    if @parent.class == SipAccount
      if @sip_account.sip_accountable.class == User
        add_breadcrumb t('users.name'), tenant_users_path(@sip_account.sip_accountable.current_tenant) 
        add_breadcrumb @sip_account.sip_accountable, tenant_user_path(@sip_account.sip_accountable.current_tenant, @sip_account.sip_accountable) 
        add_breadcrumb t('sip_accounts.index.page_title'), user_sip_accounts_path(@sip_account.sip_accountable) 
        add_breadcrumb @sip_account, user_sip_account_path(@sip_account.sip_accountable, @sip_account) 
        add_breadcrumb t('calls.index.page_title'), sip_account_calls_path(@sip_account) 
      elsif @sip_account.sip_accountable.class == Tenant
        add_breadcrumb t('sip_accounts.index.page_title'), tenant_sip_accounts_path(@sip_account.sip_accountable) 
        add_breadcrumb @sip_account, tenant_sip_account_path(@sip_account.sip_accountable, @sip_account) 
        add_breadcrumb t('calls.index.page_title'), sip_account_calls_path(@sip_account) 
      end
    end
  end
end
