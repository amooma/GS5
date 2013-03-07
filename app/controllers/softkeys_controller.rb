class SoftkeysController < ApplicationController
  load_and_authorize_resource :sip_account, :except => [:sort]
  load_and_authorize_resource :softkey, :through => [:sip_account], :except => [:sort]

  before_filter :set_available_softkey_functions, :only => [ :new, :edit, :update, :create ]
  before_filter :spread_breadcrumbs, :except => [:sort]
  
  def index
  end

  def show
  end

  def new
    @softkey = @sip_account.softkeys.build

    delete_call_forward_softkey_if_no_callforward_is_available
  end

  def create
    @softkey = @sip_account.softkeys.build(params[:softkey])
    if @softkey.save
      redirect_to sip_account_softkey_path(@softkey.sip_account, @softkey), :notice => t('softkeys.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    delete_call_forward_softkey_if_no_callforward_is_available
  end

  def update
    if @softkey.update_attributes(params[:softkey])
      redirect_to sip_account_softkey_path(@softkey.sip_account, @softkey), :notice  => t('softkeys.controller.successfuly_updated')
    else
      delete_call_forward_softkey_if_no_callforward_is_available
      
      render :edit
    end
  end

  def destroy
    @softkey.destroy
    redirect_to sip_account_softkeys_path(@softkey.sip_account), :notice => t('softkeys.controller.successfuly_destroyed')
  end

  def sort
    sip_account = Softkey.find(params[:softkey].first).sip_account

    params[:softkey].each do |softkey_id|
      sip_account.softkeys.find(softkey_id).move_to_bottom
    end

    render nothing: true
  end

  private
  def set_available_softkey_functions
    @softkey_functions = []
    SoftkeyFunction.accessible_by(current_ability, :read).each do |softkey_function|
      if GuiFunction.display?("softkey_function_#{softkey_function.name.downcase}_field_in_softkey_form", current_user)
        @softkey_functions << softkey_function
      end
    end
  end

  def spread_breadcrumbs
    if @sip_account.sip_accountable.class == User
      add_breadcrumb t('users.name'), tenant_users_path(@sip_account.sip_accountable.current_tenant) 
      add_breadcrumb @sip_account.sip_accountable, tenant_user_path(@sip_account.sip_accountable.current_tenant, @sip_account.sip_accountable) 
      add_breadcrumb t('sip_accounts.index.page_title'), user_sip_accounts_path(@sip_account.sip_accountable) 
      add_breadcrumb @sip_account, user_sip_account_path(@sip_account.sip_accountable, @sip_account) 
      add_breadcrumb t('softkeys.index.page_title'), sip_account_softkeys_path(@sip_account) 
    elsif @sip_account.sip_accountable.class == Tenant
      add_breadcrumb t('sip_accounts.index.page_title'), tenant_sip_accounts_path(@sip_account.sip_accountable) 
      add_breadcrumb @sip_account, tenant_sip_account_path(@sip_account.sip_accountable, @sip_account) 
      add_breadcrumb t('softkeys.index.page_title'), sip_account_softkeys_path(@sip_account) 
    end
  end

  def delete_call_forward_softkey_if_no_callforward_is_available
    # Don't display the call_forward option if there aren't any call_forwards to choose from.
    #
    if @softkey.sip_account.phone_numbers.map{|phone_number| phone_number.call_forwards}.flatten.count == 0
      @softkey_functions.delete_if { |softkey_function| softkey_function == SoftkeyFunction.find_by_name('call_forwarding') }
    end
  end
end
