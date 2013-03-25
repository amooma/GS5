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
  end

  def update
    if @softkey.update_attributes(params[:softkey])
      redirect_to sip_account_softkey_path(@softkey.sip_account, @softkey), :notice  => t('softkeys.controller.successfuly_updated')
    else
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
    @possible_call_forwards = @softkey.possible_call_forwards
    @softkey_functions = []
    SoftkeyFunction.accessible_by(current_ability, :read).each do |softkey_function|
      if GuiFunction.display?("softkey_function_#{softkey_function.name.downcase}_field_in_softkey_form", current_user)
        if softkey_function.name != 'call_forwarding' or @possible_call_forwards.count > 0
          @softkey_functions << softkey_function
        end
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
end
