class GroupsController < ApplicationController
  load_and_authorize_resource :group
  before_filter :spread_breadcrumbs

  def index
    @groups = Group.all
  end

  def show
    @group = Group.find(params[:id])
  end

  def new
    @group.active = true;
  end

  def create
    @group = Group.new(params[:group])
    if @group.save
      redirect_to @group, :notice => t('groups.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @group = Group.find(params[:id])
  end

  def update
    @group = Group.find(params[:id])
    if @group.update_attributes(params[:group])
      redirect_to @group, :notice  => t('groups.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @group = Group.find(params[:id])
    @group.destroy
    redirect_to groups_url, :notice => t('groups.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    add_breadcrumb t("groups.index.page_title"), groups_path
    if @group && !@group.new_record?
      add_breadcrumb @group, @group
    end
  end  
end
