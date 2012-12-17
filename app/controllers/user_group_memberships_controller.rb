class UserGroupMembershipsController < ApplicationController
  load_and_authorize_resource :user_group
  load_and_authorize_resource :user_group_membership, :through => [:user_group]
  
  before_filter :spread_breadcrumbs
  
  def index
    @potential_users_count = @user_group.tenant.users.count - @user_group.users.count
  end

  def show
  end

  def new
    @user_group_membership = @user_group.user_group_memberships.build
    @potential_users = (@user_group.tenant.users.order(:last_name) - @user_group.users)
    if @potential_users.count == 0
      redirect_to user_group_user_group_memberships_path(@user_group), :alert => t('user_group_memberships.controller.no_more_user_to_add')
    end
  end

  def create
    @user_group_membership = @user_group.user_group_memberships.build(params[:user_group_membership])
    if @user_group_membership.save
      redirect_to user_group_user_group_membership_path(@user_group, @user_group_membership), :notice => t('user_group_memberships.controller.successfuly_created')
    else
      render :new
    end
  end

  def destroy
    @user_group_membership.destroy
    redirect_to user_group_user_group_memberships_path(@user_group), :notice => t('user_group_memberships.controller.successfuly_destroyed')
  end
  
  private

  def spread_breadcrumbs
    add_breadcrumb t("user_groups.index.page_title"), tenant_user_groups_path(@user_group.tenant)
    add_breadcrumb @user_group, tenant_user_group_path(@user_group.tenant, @user_group)
    add_breadcrumb t("user_group_memberships.index.page_title"), user_group_user_group_memberships_path(@user_group)

    if @user_group_membership && !@user_group_membership.new_record?
      add_breadcrumb @user_group_membership, user_group_user_group_membership_path(@user_group, @user_group_membership)
    end
  end
  
end
