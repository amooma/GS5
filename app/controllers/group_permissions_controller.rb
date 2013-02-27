class GroupPermissionsController < ApplicationController
  load_and_authorize_resource :group
  load_and_authorize_resource :group_permission, :through => [:group]

  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    @group_permission.target_group_id = @group_permission.group_id
  end

  def create
    @group_permission = @group.group_permissions.new(params[:group_permission])
    if @group_permission.save
      redirect_to action: "index", :notice => t('group_permissions.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @group_permission.update_attributes(params[:group_permission])
      redirect_to action: "index", :notice  => t('group_permissions.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @group_permission.destroy
    redirect_to action: "index", :notice => t('group_permissions.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    add_breadcrumb t("groups.index.page_title"), groups_path
    add_breadcrumb @group, group_path(@group)
    add_breadcrumb t("group_permissions.index.page_title"), group_group_permissions_path(@group)
    if @group_permission && !@group_permission.new_record?
      add_breadcrumb @group_permission, group_group_permission_path(@group, @group_permission)
    end
  end
end
