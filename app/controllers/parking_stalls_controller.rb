class ParkingStallsController < ApplicationController
  def index
    @parking_stalls = ParkingStall.all
  end

  def show
    @parking_stall = ParkingStall.find(params[:id])
  end

  def new
    @parking_stall = ParkingStall.new
  end

  def create
    @parking_stall = ParkingStall.new(params[:parking_stall])
    if @parking_stall.save
      redirect_to @parking_stall, :notice => t('parking_stalls.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @parking_stall = ParkingStall.find(params[:id])
  end

  def update
    @parking_stall = ParkingStall.find(params[:id])
    if @parking_stall.update_attributes(params[:parking_stall])
      redirect_to @parking_stall, :notice  => t('parking_stalls.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @parking_stall = ParkingStall.find(params[:id])
    @parking_stall.destroy
    redirect_to parking_stalls_url, :notice => t('parking_stalls.controller.successfuly_destroyed')
  end
end
