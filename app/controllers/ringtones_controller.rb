class RingtonesController < ApplicationController
  load_resource :phone_number
  load_resource :sip_account
  load_resource :boss_assistant_cooperation
  load_and_authorize_resource :ringtone, :through => [:phone_number, :sip_account, :boss_assistant_cooperation]
  
  before_filter :set_parent
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    @ringtone = @parent.ringtones.build
    @ringtone.bellcore_id = GsParameter.get('default_ringtone', 'dialplan', 'parameters')
  end

  def create
    @ringtone = @parent.ringtones.build(params[:ringtone])
    if @ringtone.save
      redirect_to method( :"#{@parent.class.name.underscore}_ringtones_url" ).(@parent), :notice => t('ringtones.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @ringtone.update_attributes(params[:ringtone])
      redirect_to method( :"#{@parent.class.name.underscore}_ringtones_url" ).(@parent), :notice  => t('ringtones.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @ringtone.destroy
    redirect_to method( :"#{@parent.class.name.underscore}_ringtones_url" ).(@parent), :notice => t('ringtones.controller.successfuly_destroyed')
  end

  private
  def set_parent
    @parent = @phone_number || @boss_assistant_cooperation || @sip_account
  end

  def spread_breadcrumbs
    if @parent.class == SipAccount
      if @sip_account.sip_accountable.class == User
        add_breadcrumb t("#{@sip_account.sip_accountable.class.name.underscore.pluralize}.index.page_title"), method( :"tenant_#{@sip_account.sip_accountable.class.name.underscore.pluralize}_path" ).(@sip_account.tenant)
        add_breadcrumb @sip_account.sip_accountable, method( :"tenant_#{@sip_account.sip_accountable.class.name.underscore}_path" ).(@sip_account.tenant, @sip_account.sip_accountable)
      end
      add_breadcrumb t("sip_accounts.index.page_title"), method( :"#{@sip_account.sip_accountable.class.name.underscore}_sip_accounts_path" ).(@sip_account.sip_accountable)
      add_breadcrumb @sip_account, method( :"#{@sip_account.sip_accountable.class.name.underscore}_sip_account_path" ).(@sip_account.sip_accountable, @sip_account)
      add_breadcrumb t("ringtones.index.page_title"), sip_account_ringtones_path(@sip_account)
      if @ringtone && !@ringtone.new_record?
        add_breadcrumb @ringtone
      end
    elsif @parent.class == PhoneNumber
      @sip_account = @parent.phone_numberable
      if @sip_account.sip_accountable.class == User
        add_breadcrumb t("#{@sip_account.sip_accountable.class.name.underscore.pluralize}.index.page_title"), method( :"tenant_#{@sip_account.sip_accountable.class.name.underscore.pluralize}_path" ).(@sip_account.tenant)
        add_breadcrumb @sip_account.sip_accountable, method( :"tenant_#{@sip_account.sip_accountable.class.name.underscore}_path" ).(@sip_account.tenant, @sip_account.sip_accountable)
      end
      add_breadcrumb t("sip_accounts.index.page_title"), method( :"#{@sip_account.sip_accountable.class.name.underscore}_sip_accounts_path" ).(@sip_account.sip_accountable)
      add_breadcrumb @sip_account, method( :"#{@sip_account.sip_accountable.class.name.underscore}_sip_account_path" ).(@sip_account.sip_accountable, @sip_account)
      add_breadcrumb t("phone_numbers.index.page_title"), sip_account_phone_numbers_path(@sip_account)
      add_breadcrumb @phone_number, sip_account_phone_number_path(@sip_account, @phone_number)
      add_breadcrumb t("ringtones.index.page_title"), phone_number_ringtones_path(@phone_number)
      if @ringtone && !@ringtone.new_record?
        add_breadcrumb @ringtone
      end
    end
  end

end
