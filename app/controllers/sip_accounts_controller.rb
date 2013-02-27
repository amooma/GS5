class SipAccountsController < ApplicationController
  load_resource :user
  load_resource :tenant
  load_and_authorize_resource :sip_account, :only => [:call]
  load_and_authorize_resource :sip_account, :through => [:user, :tenant ]
 
  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs

  def index
  end

  def show
    @register_tel_protocol = "#{request.protocol}#{request.host_with_port}/sip_accounts/#{@sip_account.try(:id)}/calls/new?url=%s"
  end

  def new
    @sip_account = @parent.sip_accounts.build
    @sip_account.caller_name = @parent
    @sip_account.call_waiting = GsParameter.get('CALL_WAITING')
    @sip_account.clir = GsParameter.get('DEFAULT_CLIR_SETTING')
    @sip_account.clip = GsParameter.get('DEFAULT_CLIP_SETTING')
    @sip_account.voicemail_pin = random_pin
    @sip_account.callforward_rules_act_per_sip_account = GsParameter.get('CALLFORWARD_RULES_ACT_PER_SIP_ACCOUNT_DEFAULT')
    if @parent.class == User
      @sip_account.hotdeskable = true
    end

    # Make sure that we don't use an already taken auth_name
    #  
    loop do
      @sip_account.auth_name = SecureRandom.hex(GsParameter.get('DEFAULT_LENGTH_SIP_AUTH_NAME'))
      
      break unless SipAccount.exists?(:auth_name => @sip_account.auth_name)
    end
    @sip_account.password = SecureRandom.hex(GsParameter.get('DEFAULT_LENGTH_SIP_PASSWORD'))
  end

  def create
    @sip_account = @parent.sip_accounts.build(params[:sip_account])

    if @sip_account.auth_name.blank?
      loop do
        @sip_account.auth_name = SecureRandom.hex(GsParameter.get('DEFAULT_LENGTH_SIP_AUTH_NAME'))
        
        break unless SipAccount.exists?(:auth_name => @sip_account.auth_name)
      end
    end
    if @sip_account.password.blank?
      @sip_account.password = SecureRandom.hex(GsParameter.get('DEFAULT_LENGTH_SIP_PASSWORD'))
    end
    
    if @sip_account.save
      m = method( :"#{@parent.class.name.underscore}_sip_account_path" )
      redirect_to m.( @parent, @sip_account ), :notice => t('sip_accounts.controller.successfuly_created', :resource => @parent)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @sip_account.update_attributes(params[:sip_account])
      m = method( :"#{@parent.class.name.underscore}_sip_account_path" )
      redirect_to m.( @parent, @sip_account ), :notice  => t('sip_accounts.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @sip_account.destroy
    m = method( :"#{@parent.class.name.underscore}_sip_accounts_url" )
    redirect_to :root, :notice => t('sip_accounts.controller.successfuly_destroyed')
  end

  def call
    if !params[:url].blank?
      protocol, separator, phone_number = params[:url].partition(':')
      if ! phone_number.blank? 
        @sip_account.call(phone_number)
        render(
          :status => 200,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- CALL -->",
        )
        return;
      end
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- Number not found -->",
      )
      return;
    end

    render(
      :status => 404,
      :layout => false,
      :content_type => 'text/plain',
      :text => "<!-- Call URL not found -->",
    )
  end

  private
  def set_and_authorize_parent
    @parent = @user || @tenant
    authorize! :read, @parent
  end

  def spread_breadcrumbs
    if @user
      add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
      add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user)
      add_breadcrumb t("sip_accounts.index.page_title"), user_sip_accounts_path(@user)
      if @sip_account && !@sip_account.new_record?
        add_breadcrumb @sip_account, user_sip_account_path(@user, @sip_account)
      end
    end
    if @tenant
      add_breadcrumb t("sip_accounts.index.page_title"), tenant_sip_accounts_path(@tenant)
      if @sip_account && !@sip_account.new_record?
        add_breadcrumb @sip_account, tenant_sip_account_path(@tenant, @sip_account)
      end
    end
  end

end
