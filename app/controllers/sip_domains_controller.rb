class SipDomainsController < ApplicationController
  def index
    @sip_domains = SipDomain.all
  end

  def show
    @sip_domain = SipDomain.find(params[:id])
  end

  def new
    @sip_domain = SipDomain.new
  end

  def create
    @sip_domain = SipDomain.new(params[:sip_domain])
    if @sip_domain.save
      redirect_to @sip_domain, :notice => t('sip_domains.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @sip_domain = SipDomain.find(params[:id])
  end

  def update
    @sip_domain = SipDomain.find(params[:id])
    if @sip_domain.update_attributes(params[:sip_domain])
      redirect_to @sip_domain, :notice  => t('sip_domains.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @sip_domain = SipDomain.find(params[:id])
    @sip_domain.destroy
    redirect_to sip_domains_url, :notice => t('sip_domains.controller.successfuly_destroyed')
  end
end
