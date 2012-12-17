class AddressesController < ApplicationController
  def index
    @addresses = Address.all
  end

  def show
    @address = Address.find(params[:id])
  end

  def new
    @address = Address.new
  end

  def create
    @address = Address.new(params[:address])
    if @address.save
      redirect_to @address, :notice => t('addresses.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @address = Address.find(params[:id])
  end

  def update
    @address = Address.find(params[:id])
    if @address.update_attributes(params[:address])
      redirect_to @address, :notice  => t('addresses.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @address = Address.find(params[:id])
    @address.destroy
    redirect_to addresses_url, :notice => t('addresses.controller.successfuly_destroyed')
  end
end
