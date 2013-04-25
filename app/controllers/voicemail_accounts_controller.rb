class VoicemailAccountsController < ApplicationController
  load_resource :sip_account
  load_resource :conference
  load_resource :hunt_group
  load_resource :automatic_call_distributor
  load_resource :user
  load_resource :tenant
  load_resource :voicemail_account

  load_and_authorize_resource :phone_number, :through => [:sip_account, :conference, :hunt_group, :automatic_call_distributor, :user, :tenant]

  before_filter :set_and_authorize_parent

  def index
    @voicemail_accounts = @parent.voicemail_accounts
  end

  def show
    
  end

  def new
    @voicemail_account = @parent.voicemail_accounts.build(:active => true)
    if @parent.class == SipAccount && VoicemailAccount.where(:name => @parent.auth_name).count == 0
      @voicemail_account.name = @parent.auth_name
    else
      @voicemail_account.name = SecureRandom.hex(GsParameter.get('DEFAULT_LENGTH_SIP_AUTH_NAME'))
    end
  end

  def create
    @voicemail_account = @parent.voicemail_accounts.new(params[:voicemail_account])
    if @voicemail_account.save
      if @parent.class == User
        @email = @parent.email
      end
      @voicemail_account.voicemail_settings.create(:name => 'pin',        :value => ("%06d" % SecureRandom.random_number(999999)),  :class_type => 'String')
      @voicemail_account.voicemail_settings.create(:name => 'notify',     :value => 'true',  :class_type => 'Boolean')
      @voicemail_account.voicemail_settings.create(:name => 'attachment', :value => 'true',  :class_type => 'Boolean')
      @voicemail_account.voicemail_settings.create(:name => 'mark_read',  :value => 'true',  :class_type => 'Boolean')
      @voicemail_account.voicemail_settings.create(:name => 'purge',      :value => 'false',  :class_type => 'Boolean')
      @voicemail_account.voicemail_settings.create(:name => 'email',      :value => @email,  :class_type => 'String')
      m = method( :"#{@parent.class.name.underscore}_voicemail_accounts_url" )
      redirect_to m.( @parent ), :notice => t('voicemail_accounts.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @voicemail_account = VoicemailAccount.find(params[:id])
  end

  def update
    @voicemail_account = VoicemailAccount.find(params[:id])
    if @voicemail_account.update_attributes(params[:voicemail_account])
      m = method( :"#{@parent.class.name.underscore}_voicemail_accounts_url" )
      redirect_to m.( @parent ), :notice  => t('voicemail_accounts.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @voicemail_account = VoicemailAccount.find(params[:id])
    @voicemail_account.destroy
    m = method( :"#{@parent.class.name.underscore}_voicemail_accounts_url" )
    redirect_to m.( @parent ), :notice => t('voicemail_accounts.controller.successfuly_destroyed')
  end

  private
  def set_and_authorize_parent
    @parent = @sip_account || @conference || @hunt_group || @automatic_call_distributor || @user || @tenant

    authorize! :read, @parent
  end

end
