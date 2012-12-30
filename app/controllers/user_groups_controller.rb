class UserGroupsController < ApplicationController
  load_resource :tenant
  load_resource :user
  load_and_authorize_resource :user_group, :through => [:tenant, :user]
  
  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs
  
  def index
  end

  def show
  end

  def new
    @user_group = @parent.user_groups.build
  end

  def create
    @user_group = @parent.user_groups.build(params[:user_group])
    if @user_group.save
      redirect_to [@parent, @user_group], :notice => t('user_groups.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user_group.update_attributes(params[:user_group])
      redirect_to [@parent, @user_group], :notice  => t('user_groups.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @user_group.destroy
    redirect_to method( :"#{@parent.class.name.underscore}_user_groups_path" ).(@parent), :notice => t('user_groups.controller.successfuly_destroyed')
  end
  
  private

  def set_and_authorize_parent
    @parent = @user || @tenant
    authorize! :read, @parent
  end

  def spread_breadcrumbs
    if @tenant
      add_breadcrumb t("user_groups.index.page_title"), tenant_user_groups_path(@tenant)
      if @user_group && !@user_group.new_record?
        add_breadcrumb @user_group, tenant_user_group_path(@tenant, @user_group)
      end
    end

    if @user
      add_breadcrumb t("users.index.page_title"), tenant_users_path(@parent)
      add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user)
      add_breadcrumb t("user_groups.index.page_title"), user_user_groups_path(@user)
      if @user_group && !@user_group.new_record?
        add_breadcrumb @user_group, user_user_group_path(@user, @user_group)
      end
    end
  end
  
end
