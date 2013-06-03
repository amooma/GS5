class PagerGroupDestinationsController < ApplicationController
  def index
    @pager_group_destinations = PagerGroupDestination.all
  end

  def show
    @pager_group_destination = PagerGroupDestination.find(params[:id])
  end

  def new
    @pager_group_destination = PagerGroupDestination.new
  end

  def create
    @pager_group_destination = PagerGroupDestination.new(params[:pager_group_destination])
    if @pager_group_destination.save
      redirect_to @pager_group_destination, :notice => t('pager_group_destinations.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @pager_group_destination = PagerGroupDestination.find(params[:id])
  end

  def update
    @pager_group_destination = PagerGroupDestination.find(params[:id])
    if @pager_group_destination.update_attributes(params[:pager_group_destination])
      redirect_to @pager_group_destination, :notice  => t('pager_group_destinations.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @pager_group_destination = PagerGroupDestination.find(params[:id])
    @pager_group_destination.destroy
    redirect_to pager_group_destinations_url, :notice => t('pager_group_destinations.controller.successfuly_destroyed')
  end
end
