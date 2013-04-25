class VoicemailSettingsController < ApplicationController
  load_and_authorize_resource :voicemail_account
  load_and_authorize_resource :voicemail_setting, :through => [:voicemail_account]

  def index
    @voicemail_settings = @voicemail_account.voicemail_settings
  end

  def show
  end

  def new
    @names_possible = []
    VoicemailSetting::VOICEMAIL_SETTINGS.keys.each do |name|
      if @voicemail_account.voicemail_settings.where(:name => name).first
        next
      end

      label = t("voicemail_settings.settings.#{name}")
      if label =~ /^translation missing/
        label = name.to_s.gsub('_', ' ').capitalize;
      end

      @names_possible << [label, name]
    end
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
    @input_type = VoicemailSetting::VOICEMAIL_SETTINGS.fetch(@voicemail_setting.name,{}).fetch(:input, 'String')
    @input_html = VoicemailSetting::VOICEMAIL_SETTINGS.fetch(@voicemail_setting.name,{}).fetch(:html, {})
  end

  def update
    @voicemail_setting = @voicemail_account.voicemail_settings.find(params[:id])
    if @voicemail_setting.update_attributes(params[:voicemail_setting])
      m = method( :"#{@voicemail_account.voicemail_accountable.class.name.underscore}_voicemail_account_path" )
      redirect_to m.( @voicemail_account.voicemail_accountable, @voicemail_account ), :notice  => t('voicemail_settings.controller.successfuly_updated')
    else
      @input_type = VoicemailSetting::VOICEMAIL_SETTINGS.fetch(@voicemail_setting.name,{}).fetch(:input, 'String')
      @input_html = VoicemailSetting::VOICEMAIL_SETTINGS.fetch(@voicemail_setting.name,{}).fetch(:html, {})
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
