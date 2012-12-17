class VoicemailSettingsController < ApplicationController
  load_resource :sip_account
  load_and_authorize_resource :voicemail_setting, :through => :sip_account, :singleton => true

  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs
  before_filter :voicemail_defaults, :only => [:index, :show, :new, :create, :edit]

  def index
    render :edit
  end

  def show
    render :edit
  end

  def new
    render :edit
  end

  def create
    @sip_account = SipAccount.where(:id => params[:sip_account_id]).first
    params[:voicemail_setting][:username] = @sip_account.auth_name
    params[:voicemail_setting][:domain] = @sip_account.sip_domain.try(:host)
    @voicemail_setting = VoicemailSetting.new(params[:voicemail_setting])
    if @voicemail_setting.save
      redirect_to sip_account_voicemail_settings_path(@sip_account), :notice => t('voicemail_settings.controller.successfuly_created')
    else
      render :action => 'edit'
    end
  end

  def edit

  end

  def update
    if @voicemail_setting.update_attributes(params[:voicemail_setting])
      redirect_to sip_account_voicemail_settings_path(@sip_account), :notice  => t('voicemail_settings.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
   
  end

  private
  def set_and_authorize_parent
    @parent = @sip_account

    authorize! :read, @parent

    @show_path_method = method( :"#{@parent.class.name.underscore}_voicemail_setting_path" )
    @index_path_method = method( :"#{@parent.class.name.underscore}_voicemail_settings_path" )
    @new_path_method = method( :"new_#{@parent.class.name.underscore}_voicemail_setting_path" )
    @edit_path_method = method( :"edit_#{@parent.class.name.underscore}_voicemail_setting_path" )
  end

  def spread_breadcrumbs
    if @parent.class == SipAccount
     if @sip_account.sip_accountable.class == User
       add_breadcrumb t("#{@sip_account.sip_accountable.class.name.underscore.pluralize}.index.page_title"), method( :"tenant_#{@sip_account.sip_accountable.class.name.underscore.pluralize}_path" ).(@sip_account.tenant)
       add_breadcrumb @sip_account.sip_accountable, method( :"tenant_#{@sip_account.sip_accountable.class.name.underscore}_path" ).(@sip_account.tenant, @sip_account.sip_accountable)
     end
     add_breadcrumb t("sip_accounts.index.page_title"), method( :"#{@sip_account.sip_accountable.class.name.underscore}_sip_accounts_path" ).(@sip_account.sip_accountable)
     add_breadcrumb @sip_account, method( :"#{@sip_account.sip_accountable.class.name.underscore}_sip_account_path" ).(@sip_account.sip_accountable, @sip_account)
     add_breadcrumb t("voicemail_settings.index.page_title"), sip_account_voicemail_settings_path(@sip_account)
    end
  end

  def voicemail_defaults
    path = "/opt/freeswitch/storage/voicemail/default/#{@sip_account.sip_domain.host}/#{@sip_account.auth_name}/"
    @greeting_files = Dir.glob("#{path}*greeting*.wav").collect {|r| [ File.basename(r), File.expand_path(r) ] }
    @name_files = Dir.glob("#{path}*name*.wav").collect {|r| [ File.basename(r), File.expand_path(r) ] }

    if @voicemail_setting.blank? then
      @voicemail_setting = @sip_account.voicemail_setting
    end

    if @voicemail_setting.blank?
      @voicemail_setting = VoicemailSetting.new
      @voicemail_setting.notify = true
      @voicemail_setting.attachment = true
      @voicemail_setting.mark_read = true
      @voicemail_setting.purge = false
    end
  end

end
