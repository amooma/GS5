class VoicemailSettingsController < ApplicationController
  load_and_authorize_resource :voicemail_account
  load_and_authorize_resource :voicemail_setting, :through => [:voicemail_account]

  def index
    @voicemail_settings = @voicemail_account.voicemail_settings
  end

  def show
  end

  def new
  end

  def create
    @voicemail_setting = @voicemail_account.voicemail_settings.build(params[:voicemail_setting])
    @voicemail_setting.class_type = VoicemailSetting::VOICEMAIL_SETTINGS[@voicemail_setting.name]
    if @voicemail_setting.save
      m = method( :"#{@voicemail_account.voicemail_accountable.class.name.underscore}_voicemail_account_path" )
      redirect_to m.( @voicemail_account.voicemail_accountable, @voicemail_account ), :notice => t('voicemail_settings.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @voicemail_setting = @voicemail_account.voicemail_settings.find(params[:id])
    @no_edit = {
      :name => { 
        :input => VoicemailSetting::VOICEMAIL_SETTINGS.fetch(@voicemail_setting.name,{}).fetch(:input, {}),
        :name => @voicemail_setting.name.to_s,
        :html => VoicemailSetting::VOICEMAIL_SETTINGS.fetch(@voicemail_setting.name,{}).fetch(:html, {}),
      }, 
      :description => true
    }
  end

  def update
    @voicemail_setting = @voicemail_account.voicemail_settings.find(params[:id])
    if @voicemail_setting.update_attributes(params[:voicemail_setting])
      m = method( :"#{@voicemail_account.voicemail_accountable.class.name.underscore}_voicemail_account_path" )
      redirect_to m.( @voicemail_account.voicemail_accountable, @voicemail_account ), :notice  => t('voicemail_settings.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @voicemail_setting = @voicemail_account.voicemail_settings.find(params[:id])
    @voicemail_setting.destroy
    m = method( :"#{@voicemail_account.voicemail_accountable.class.name.underscore}_voicemail_account_path" )
    redirect_to m.( @voicemail_account.voicemail_accountable, @voicemail_account ), :notice => t('voicemail_settings.controller.successfuly_destroyed')
  end
end
