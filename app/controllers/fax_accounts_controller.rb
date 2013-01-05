class FaxAccountsController < ApplicationController
  load_resource :user
  load_resource :user_group
  load_and_authorize_resource :fax_account, :through => [:user, :user_group]

  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs
  
  def index
  end

  def show
  end

  def new
    @fax_account = @parent.fax_accounts.build
    @fax_account.name = generate_a_new_name(@parent, @fax_account)
    @fax_account.days_till_auto_delete = GsParameter.get('DAYS_TILL_AUTO_DELETE')
    @fax_account.retries = GsParameter.get('DEFAULT_NUMBER_OF_RETRIES')
    @fax_account.station_id = @parent.to_s
    @fax_account.phone_numbers.build
    if @parent.class == User && !@parent.email.blank?
      @fax_account.email = @parent.email
    end
  end

  def create
    @fax_account = @parent.fax_accounts.build(params[:fax_account])
    if @fax_account.save
      m = method( :"#{@parent.class.name.underscore}_fax_account_path" )
      redirect_to m.( @parent, @fax_account ), :notice => t('fax_accounts.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @fax_account.update_attributes(params[:fax_account])
      m = method( :"#{@parent.class.name.underscore}_fax_account_path" )
      redirect_to m.( @parent, @fax_account ), :notice => t('fax_accounts.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @fax_account.destroy
    m = method( :"#{@parent.class.name.underscore}_fax_accounts_url" )
    redirect_to m.( @parent ), :notice => t('fax_accounts.controller.successfuly_destroyed')
  end

  private
  def set_and_authorize_parent
    @parent = @user || @user_group
    authorize! :read, @parent
  end

  def spread_breadcrumbs
    if @parent && @parent.class == User
      add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
      add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user)
      add_breadcrumb t("fax_accounts.index.page_title"), user_fax_accounts_path(@user)
      if @fax_account && !@fax_account.new_record?
        add_breadcrumb @fax_account, user_fax_account_path(@user, @fax_account)
      end
    end

    if @parent && @parent.class == UserGroup
      @user_group = @parent
      add_breadcrumb t("user_groups.index.page_title"), tenant_user_groups_path(@user_group.tenant)
      add_breadcrumb @user_group, tenant_user_group_path(@user_group.tenant, @user_group)
      add_breadcrumb t("fax_accounts.index.page_title"), user_group_fax_accounts_path(@user_group)
      if @fax_account && !@fax_account.new_record?
        add_breadcrumb @fax_account, user_group_fax_account_path(@user_group, @fax_account)
      end
    end
  end

end
