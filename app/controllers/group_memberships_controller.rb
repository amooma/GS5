class GroupMembershipsController < ApplicationController
  load_and_authorize_resource :group
  load_and_authorize_resource :group_membership, :through => [:group]

  def index
  end

  def show
  end

  def new
  end

  def create
    if params[:group_membership][:item_type].blank?
      params[:group_membership][:item_type] = @group.group_memberships.first.item_type
    end
    @group_membership = @group.group_memberships.new(params[:group_membership])
    if @group_membership.save
      redirect_to action: "index", :notice => t('group_memberships.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @group_membership.update_attributes(params[:group_membership])
      redirect_to action: "index", :notice  => t('group_memberships.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @group_membership.destroy
    redirect_to action: "index", :notice => t('group_memberships.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    add_breadcrumb t("groups.index.page_title"), groups_path
    add_breadcrumb @group, group_path(@group)
    add_breadcrumb t("group_memberships.index.page_title"), group_group_memberships_path(@group)
    if @group_membership && !@group_membership.new_record?
      add_breadcrumb @group_membership, group_group_membership_path(@group, @group_membership)
    end
  end
end
