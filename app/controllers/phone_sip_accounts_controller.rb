class PhoneSipAccountsController < ApplicationController
  load_and_authorize_resource :phone
  load_and_authorize_resource :phone_sip_account, :through => [:phone]
  
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    @available_sip_accounts = @phone.phoneable.sip_accounts 

    # Ensure a SipAccount is used on a single phone only.
    #
    @available_sip_accounts = @available_sip_accounts.delete_if { |x| x.phone_sip_account_ids.count > 0 }

    if @available_sip_accounts.count == 0 
      redirect_to method( :"new_#{@phone.phoneable.class.name.underscore}_sip_account_path" ).(@phone.phoneable), :alert => t('phone_sip_accounts.controller.no_existing_sip_accounts_warning')
    else
      @phone_sip_account = @phone.phone_sip_accounts.build(:sip_account_id => @available_sip_accounts.first.try(:id))
    end
  end

  def create
    @phone_sip_account = @phone.phone_sip_accounts.build(params[:phone_sip_account])
    if @phone_sip_account.save
      redirect_to method( :"#{@phone_sip_account.phone.phoneable.class.name.underscore}_phone_path" ).(@phone_sip_account.phone.phoneable, @phone_sip_account.phone), :notice => t('phone_sip_accounts.controller.successfuly_created')
    else
      render :new
    end
  end

  def destroy
    @phone_sip_account.destroy
    redirect_to method( :"#{@phone_sip_account.phone.phoneable.class.name.underscore}_phone_path" ).(@phone_sip_account.phone.phoneable, @phone_sip_account.phone), :notice => t('phone_sip_accounts.controller.successfuly_destroyed')
  end

  private

  def spread_breadcrumbs
    if @phone.phoneable.class == User
      user = @phone.phoneable
      add_breadcrumb t('users.index.page_title'), tenant_users_path(user.current_tenant) 
      add_breadcrumb user, tenant_user_path(user.current_tenant, user) 
      add_breadcrumb t('phones.index.page_title'), user_phones_path(user) 
    elsif @phone.phoneable.class == Tenant
      tenant = @phone.phoneable
      add_breadcrumb t('phones.index.page_title'), tenant_phones_path(tenant) 
    end
    add_breadcrumb @phone, method( :"#{@phone.phoneable.class.name.underscore}_phone_path" ).(@phone.phoneable, @phone)
    add_breadcrumb t('phone_sip_accounts.index.page_title'), phone_phone_sip_accounts_path(@phone) 
    if @phone_sip_account && !@phone_sip_account.new_record?
      add_breadcrumb @phone_sip_account, phone_phone_sip_account_path(@phone, @phone_sip_account) 
    end
  end

end
