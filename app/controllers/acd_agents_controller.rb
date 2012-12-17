class AcdAgentsController < ApplicationController
  load_and_authorize_resource :automatic_call_distributor
  load_and_authorize_resource :acd_agent, :through => [:automatic_call_distributor]

  before_filter :spread_breadcrumbs

  def index
    if params[:active]
      if params[:active].downcase == 'true'
        @acd_agents = @acd_agents.where(:active => true)
      elsif params[:active].downcase == 'false'
        @acd_agents = @acd_agents.where(:active => false)
      end
    end
  end

  def show
    @acd_agent = AcdAgent.find(params[:id])
  end

  def new
    @acd_agent = @automatic_call_distributor.acd_agents.build
    i = @automatic_call_distributor.acd_agents.count
    loop do
      i += 1
      break unless @automatic_call_distributor.acd_agents.where(:name => "#{t('acd_agents.name')} #{i}").count > 0
    end
    @acd_agent.name = "#{t('acd_agents.name')} #{i}"
    @acd_agent.status = 'active'
    @acd_agent.calls_answered = 0
  end

  def create
    @acd_agent = @automatic_call_distributor.acd_agents.build(params[:acd_agent])
    if @acd_agent.save
      redirect_to automatic_call_distributor_acd_agent_path(@automatic_call_distributor, @acd_agent), :notice => t('acd_agents.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @acd_agent = AcdAgent.find(params[:id])
  end

  def update
    @acd_agent = AcdAgent.find(params[:id])
    if @acd_agent.update_attributes(params[:acd_agent])
      redirect_to automatic_call_distributor_acd_agent_path(@automatic_call_distributor, @acd_agent), :notice => t('acd_agents.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @acd_agent = AcdAgent.find(params[:id])
    @acd_agent.destroy
    redirect_to automatic_call_distributor_acd_agents_path(@automatic_call_distributor), :notice => t('acd_agents.controller.successfuly_destroyed')
  end

  def spread_breadcrumbs
    if @automatic_call_distributor.automatic_call_distributorable.class == User
      add_breadcrumb t("#{@automatic_call_distributor.automatic_call_distributorable.class.name.underscore.pluralize}.index.page_title"), method( :"tenant_#{@automatic_call_distributor.automatic_call_distributorable.class.name.underscore.pluralize}_path" ).(@automatic_call_distributor.tenant)
      add_breadcrumb @automatic_call_distributor.automatic_call_distributorable, method( :"tenant_#{@automatic_call_distributor.automatic_call_distributorable.class.name.underscore}_path" ).(@automatic_call_distributor.tenant, @automatic_call_distributor.automatic_call_distributorable)
    end
    add_breadcrumb t("automatic_call_distributors.index.page_title"), method( :"#{@automatic_call_distributor.automatic_call_distributorable.class.name.underscore}_automatic_call_distributors_path" ).(@automatic_call_distributor.automatic_call_distributorable)
    add_breadcrumb @automatic_call_distributor, method( :"#{@automatic_call_distributor.automatic_call_distributorable.class.name.underscore}_automatic_call_distributor_path" ).(@automatic_call_distributor.automatic_call_distributorable, @automatic_call_distributor)
    add_breadcrumb t("acd_agents.index.page_title"), automatic_call_distributor_acd_agents_path(@automatic_call_distributor)
    if @acd_agent && !@acd_agent.new_record?
      add_breadcrumb @acd_agent, automatic_call_distributor_acd_agent_path(@automatic_call_distributor, @acd_agent)
    end
  end
end
