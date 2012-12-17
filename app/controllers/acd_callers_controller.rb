class AcdCallersController < ApplicationController
  def index
    @acd_callers = AcdCaller.all
  end

  def show
    @acd_caller = AcdCaller.find(params[:id])
  end

  def new
    @acd_caller = AcdCaller.new
  end

  def create
    @acd_caller = AcdCaller.new(params[:acd_caller])
    if @acd_caller.save
      redirect_to @acd_caller, :notice => t('acd_callers.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @acd_caller = AcdCaller.find(params[:id])
  end

  def update
    @acd_caller = AcdCaller.find(params[:id])
    if @acd_caller.update_attributes(params[:acd_caller])
      redirect_to @acd_caller, :notice  => t('acd_callers.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @acd_caller = AcdCaller.find(params[:id])
    @acd_caller.destroy
    redirect_to acd_callers_url, :notice => t('acd_callers.controller.successfuly_destroyed')
  end
end
