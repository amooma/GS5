class PhonesController < ApplicationController
  load_resource :tenant
  load_resource :user
  load_and_authorize_resource :phone, :through => [:tenant, :user]

  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    @phone = @phoneable.phones.build()

    set_fallback_sip_accounts
    
    # Use the last phone.phone_model as the default.
    #
    @phone.phone_model_id = Phone.last.try(:phone_model).try(:id)
  end

  def create
    @phone = @phoneable.phones.build(params[:phone])
    if !@tenant
      @tenant = @user.current_tenant
    end
    @phone.tenant = @tenant
    if @phone.save
      m = method( :"#{@phoneable.class.name.underscore}_phone_path" )
      redirect_to m.( @phoneable, @phone ), :notice => t('phones.controller.successfuly_created')
    else
      set_fallback_sip_accounts
      render :new
    end
  end

  def edit
    set_fallback_sip_accounts
  end

  def update
    if @phone.update_attributes(params[:phone])
      m = method( :"#{@phoneable.class.name.underscore}_phone_path" )
      redirect_to m.( @phoneable, @phone ), :notice => t('phones.controller.successfuly_updated')
    else
      set_fallback_sip_accounts
      render :edit
    end
  end

  def destroy
    @phone.destroy
    m = method( :"#{@phoneable.class.name.underscore}_phones_url" )
    redirect_to m.( @phoneable ), :notice => t('phones.controller.successfuly_destroyed')
  end

  private
  def set_and_authorize_parent
    @phoneable = (@user || @tenant)
    @parent = @phoneable
    authorize! :read, @parent
    @nesting_prefix = @phoneable ? "#{@phoneable.class.name.underscore}_" : ''
  end

  def spread_breadcrumbs
    if @user
      add_breadcrumb t('users.index.page_title'), tenant_users_path(@user.current_tenant) 
      add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user) 
      add_breadcrumb t('phones.index.page_title'), user_phones_path(@user) 
    elsif @tenant
      add_breadcrumb t('phones.index.page_title'), tenant_phones_path(@tenant) 
    end
    if @phone && !@phone.new_record?
      add_breadcrumb @phone, method( :"#{@phone.phoneable.class.name.underscore}_phone_path" ).(@phone.phoneable, @phone)
    end
  end

  def set_fallback_sip_accounts
    used_sip_account_ids = Phone.pluck(:fallback_sip_account_id) + PhoneSipAccount.pluck(:sip_account_id)
    if @phone
      used_sip_account_ids = used_sip_account_ids - [ @phone.fallback_sip_account_id ]
    end
    @fallback_sip_accounts = SipAccount.where(:sip_accountable_type => 'Tenant') - SipAccount.where(:id => used_sip_account_ids)
  end
  
end
