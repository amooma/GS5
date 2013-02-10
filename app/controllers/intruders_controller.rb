class IntrudersController < ApplicationController
  def index
    @intruders = Intruder.all
  end

  def show
    @intruder = Intruder.find(params[:id])
  end

  def new
    @intruder = Intruder.new
  end

  def create
    @intruder = Intruder.new(params[:intruder])
    if @intruder.save
      redirect_to @intruder, :notice => t('intruders.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @intruder = Intruder.find(params[:id])
  end

  def update
    @intruder = Intruder.find(params[:id])
    if @intruder.update_attributes(params[:intruder])
      redirect_to @intruder, :notice  => t('intruders.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @intruder = Intruder.find(params[:id])
    @intruder.destroy
    redirect_to intruders_url, :notice => t('intruders.controller.successfuly_destroyed')
  end
end
