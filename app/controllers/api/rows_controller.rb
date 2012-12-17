class Api::RowsController < ApplicationController
  before_filter :check_remote_ip_address_whitelist

  def index
    @rows = Api::Row.all

    respond_to do |format|
      format.xml { render xml: @rows }
    end
  end

  def show
    if params[:user_name]
      @row = Api::Row.find_by_user_name(params[:user_name])
    else
      @row = Api::Row.find(params[:id])
    end

    respond_to do |format|
      format.xml { render xml: @row }
    end
  end

  def new
    @row = Api::Row.new

    respond_to do |format|
      format.xml { render xml: @row }
    end
  end

  def edit
    if params[:user_name]
      @row = Api::Row.find_by_user_name(params[:user_name])
    else
      @row = Api::Row.find(params[:id])
    end
  end

  def create
    @row = Api::Row.new(params[:row])

    respond_to do |format|
      if @row.save
        @row.create_a_new_gemeinschaft_user

        format.xml { render xml: @row, status: :created, location: @row }
      else
        format.xml { render xml: @row.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if params[:user_name]
      @row = Api::Row.find_by_user_name(params[:user_name])
    else
      @row = Api::Row.find(params[:id])
    end

    respond_to do |format|
      if @row.update_attributes(params[:row])
        @row.update_user_data
        format.xml { head :no_content }
      else
        format.xml { render xml: @row.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if params[:user_name]
      @row = Api::Row.find_by_user_name(params[:user_name])
    else
      @row = Api::Row.find(params[:id])
    end
    @row.destroy

    respond_to do |format|
      format.xml { head :no_content }
    end
  end

  private

  def check_remote_ip_address_whitelist
    if !(REMOTE_IP_ADDRESS_WHITELIST.empty? or REMOTE_IP_ADDRESS_WHITELIST.include?(ENV['REMOTE_ADDR']))
      redirect_to root_url
    end
  end
end
