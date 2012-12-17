class RingtonesController < ApplicationController
  load_resource :phone_number
  load_resource :boss_assistant_cooperation
  load_and_authorize_resource :ringtone, :through => [:phone_number, :boss_assistant_cooperation]
  
  before_filter :set_parent
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    @ringtone = @parent.ringtones.build
  end

  def create
    @ringtone = @parent.ringtones.build(params[:ringtone])
    if @ringtone.save
      redirect_to phone_number_ringtone_path(@parent, @ringtone), :notice => t('ringtones.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @ringtone.update_attributes(params[:ringtone])
      redirect_to method( :"#{@parent.class.name.underscore}_ringtone_path" ).(@ringtone.ringtoneable, @ringtone), :notice  => t('ringtones.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @ringtone.destroy
    redirect_to phone_number_ringtones_path(@parent), :notice => t('ringtones.controller.successfuly_destroyed')
  end

  private
  def set_parent
    @parent = @phone_number || @boss_assistant_cooperation
  end

  def spread_breadcrumbs
    if @parent.class == PhoneNumber && @parent.phone_numberable.class == SipAccount
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
        add_breadcrumb @ringtone, phone_number_ringtone_path(@phone_number, @ringtone)
      end
    end
  end

end
