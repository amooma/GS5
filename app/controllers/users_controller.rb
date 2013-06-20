class UsersController < ApplicationController
  load_resource :tenant
  load_resource :user_group
  load_and_authorize_resource :user, :through => [:tenant, :user_group]
  
  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs

  helper_method :sort_column, :sort_descending
  
  def index
    @users = @parent.users.order(sort_column + ' ' + (sort_descending ? 'DESC' : 'ASC')).paginate(
      :page => params[:page],
      :per_page => GsParameter.get('DEFAULT_PAGINATION_ENTRIES_PER_PAGE')
    )
  end

  def show
    @phone_books = PhoneBook.accessible_by( Ability.new( @user ), :read )
  end

  def new
    @user = @parent.users.build(params[:user])
    @user.male = true
    @user.send_voicemail_as_email_attachment = true
  end

  def create
    @user = @parent.users.build(params[:user])
    if @user.save
      if VoicemailAccount.where(:name => "user_#{@user.user_name}").count == 0
        @user.voicemail_accounts.create(:name => "user_#{@user.user_name}", :active => true )
      else
        @user.voicemail_accounts.create(:active => true)
      end
      
      if @parent.class == Tenant
        @parent.tenant_memberships.create(:user => @user)
        if @parent.user_groups.exists?(:name => 'Users')
          @parent.user_groups.where(:name => 'Users').first.user_group_memberships.create(:user => @user)
        end
        redirect_to tenant_user_url( @parent, @user), :notice => t('users.controller.successfuly_created', :resource => @user)
      else
        redirect_to tenant_user_path(@user.current_tenant, @user), :notice => t('users.controller.successfuly_created_and_login', :resource => @user)
      end
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(params[:user])
      # Make sure that the flash notice gets rendered in the correct language.
      I18n.locale = @user.language.code.downcase 

      redirect_to tenant_user_path(@user.current_tenant, @user), :notice  => t('users.controller.successfuly_updated')
    else
      render :edit
    end
  end
    
  def destroy
    @user.destroy
    redirect_to :back, :notice => t('users.controller.successfuly_destroyed')
  end

  def destroy_avatar
    user = User.find(params[:user_id])
    user.remove_image = true  # https://github.com/jnicklas/carrierwave/issues/360
    user.remove_image!
    user.save
    user.reload   
    user.image.remove!
    user.save
    redirect_to @parent, :notice => t('users.controller.avatar_destroyed')
  end

  private
  def set_and_authorize_parent
    @parent = @tenant || @user_group
    authorize! :read, @parent
  end

  def spread_breadcrumbs
    if @tenant
      add_breadcrumb t("users.index.page_title"), tenant_users_path(@tenant)

      if @user && !@user.new_record?
        add_breadcrumb @user, tenant_user_path(@tenant, @user)
      end
    end
  end

  def sort_descending
    params[:desc].to_s == 'true'
  end

  def sort_column
    User.column_names.include?(params[:sort]) ? params[:sort] : 'id'
  end

end
