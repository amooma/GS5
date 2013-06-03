class PagerGroupsController < ApplicationController
  def index
    @pager_groups = PagerGroup.all
  end

  def show
    @pager_group = PagerGroup.find(params[:id])
  end

  def new
    @pager_group = PagerGroup.new
  end

  def create
    @pager_group = PagerGroup.new(params[:pager_group])
    if @pager_group.save
      redirect_to @pager_group, :notice => t('pager_groups.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @pager_group = PagerGroup.find(params[:id])
  end

  def update
    @pager_group = PagerGroup.find(params[:id])
    if @pager_group.update_attributes(params[:pager_group])
      redirect_to @pager_group, :notice  => t('pager_groups.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @pager_group = PagerGroup.find(params[:id])
    @pager_group.destroy
    redirect_to pager_groups_url, :notice => t('pager_groups.controller.successfuly_destroyed')
  end
end
