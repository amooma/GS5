class SimCardsController < ApplicationController
  load_and_authorize_resource :sim_card_provider
  load_and_authorize_resource :sim_card, :through => [:sim_card_provider]

  before_filter :set_parent
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    @sim_card = @sim_card_provider.sim_cards.build

    @with_phones_connected_sip_account_ids = SipAccount.where(:id => PhoneSipAccount.pluck(:sip_account_id)).pluck(:id)
    @with_sim_cards_connected_sip_account_ids = SimCard.pluck(:sip_account_id)
    @available_sip_account_ids = SipAccount.pluck(:id) - (@with_phones_connected_sip_account_ids + @with_sim_cards_connected_sip_account_ids)

    @available_sip_accounts = SipAccount.where(:id => @available_sip_account_ids)

    if @available_sip_accounts.count == 0 
      redirect_to sim_card_provider_sim_cards_path(@sim_card_provider), :alert => t('sim_cards.controller.no_existing_sip_accounts_warning')
    end

  end

  def create
    @sim_card = @sim_card_provider.sim_cards.build(params[:sim_card])
    if @sim_card.save
      redirect_to [@sim_card_provider, @sim_card], :notice => t('sim_cards.controller.successfuly_created')
    else
      render :new
    end
  end

  def destroy
    @sim_card.destroy
    redirect_to sim_card_provider_sim_cards_url(@sim_card_provider), :notice => t('sim_cards.controller.successfuly_destroyed')
  end

  private
  def set_parent
    @parent = @sim_card_provider
  end

  def spread_breadcrumbs
    add_breadcrumb t("sim_card_providers.index.page_title"), sim_card_providers_path
    add_breadcrumb @sim_card_provider, sim_card_provider_path(@sim_card_provider)
    add_breadcrumb t("sim_cards.index.page_title"), sim_card_provider_sim_cards_path(@sim_card_provider)
    if @sim_card && !@sim_card.new_record?
      add_breadcrumb @sim_card, sim_card_provider_sim_card_path(@sim_card_provider, @sim_card)
    end
  end

end
