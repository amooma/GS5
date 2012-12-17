class AutomaticCallDistributorsController < ApplicationController
  DEFAULT_STRATEGY = 'round_robin'
  DEFAULT_MAX_CALLERS = 50
  DEFAULT_AGENT_TIMEOUT = 20
  DEFAULT_RETRY_TIMEOUT = 10
  DEFAULT_JOIN = 'agents_active'
  DEFAULT_LEAVE = 'no_agents_active'

  load_resource :user
  load_resource :tenant
  load_and_authorize_resource :automatic_call_distributor, :through => [:user, :tenant ]
 
  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs

  def index
    @automatic_call_distributors = AutomaticCallDistributor.all
  end

  def show
    @automatic_call_distributor = AutomaticCallDistributor.find(params[:id])
  end

  def new
    i = @parent.automatic_call_distributors.count
    loop do
      i += 1
      break unless @parent.automatic_call_distributors.where(:name => "#{t('automatic_call_distributors.name')} #{i}").count > 0
    end
    @strategies = AutomaticCallDistributor::STRATEGIES.collect {|r| [ t("automatic_call_distributors.strategies.#{r.to_s}"), r.to_s ] }
    @join_on = AutomaticCallDistributor::JOIN_ON.collect {|r| [ t("automatic_call_distributors.join_on.#{r.to_s}"), r.to_s ] }
    @leave_on = AutomaticCallDistributor::LEAVE_ON.collect {|r| [ t("automatic_call_distributors.leave_on.#{r.to_s}"), r.to_s ] }
    @automatic_call_distributor = @parent.automatic_call_distributors.build(
      :name => "#{t('automatic_call_distributors.name')} #{i}",
      :strategy => DEFAULT_STRATEGY,
      :max_callers => DEFAULT_MAX_CALLERS, 
      :retry_timeout => DEFAULT_RETRY_TIMEOUT, 
      :agent_timeout => DEFAULT_AGENT_TIMEOUT,
      :join => DEFAULT_JOIN,
      :leave => DEFAULT_LEAVE,
    )

  end

  def create
    @automatic_call_distributor = @parent.automatic_call_distributors.build(params[:automatic_call_distributor])
    if @automatic_call_distributor.save
      m = method( :"#{@parent.class.name.underscore}_automatic_call_distributor_path" )
      redirect_to m.( @parent, @automatic_call_distributor ), :notice => t('automatic_call_distributors.controller.successfuly_created', :resource => @parent)
    else
      render :new
    end
  end

  def edit
    @strategies = AutomaticCallDistributor::STRATEGIES.collect {|r| [ t("automatic_call_distributors.strategies.#{r.to_s}"), r.to_s ] }
    @join_on = AutomaticCallDistributor::JOIN_ON.collect {|r| [ t("automatic_call_distributors.join_on.#{r.to_s}"), r.to_s ] }
    @leave_on = AutomaticCallDistributor::LEAVE_ON.collect {|r| [ t("automatic_call_distributors.leave_on.#{r.to_s}"), r.to_s ] }
    @automatic_call_distributor = AutomaticCallDistributor.find(params[:id])
  end

  def update
    if @automatic_call_distributor.update_attributes(params[:automatic_call_distributor])
      m = method( :"#{@parent.class.name.underscore}_automatic_call_distributor_path" )
      redirect_to m.( @parent, @automatic_call_distributor ), :notice  => t('automatic_call_distributors.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @automatic_call_distributor = AutomaticCallDistributor.find(params[:id])
    @automatic_call_distributor.destroy
    m = method( :"#{@parent.class.name.underscore}_automatic_call_distributors_url" )
    redirect_to m.( @parent ), :notice => t('automatic_call_distributors.controller.successfuly_destroyed')
  end

  private
  def set_and_authorize_parent
    @parent = @user || @tenant
    authorize! :read, @parent
  end

  def spread_breadcrumbs
    if @user
      add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
      add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user)
      add_breadcrumb t("automatic_call_distributors.index.page_title"), user_automatic_call_distributors_path(@user)
      if @automatic_call_distributor && !@automatic_call_distributor.new_record?
        add_breadcrumb @automatic_call_distributor, user_automatic_call_distributor_path(@user, @automatic_call_distributor)
      end
    end
    if @tenant
      add_breadcrumb t("automatic_call_distributors.index.page_title"), tenant_automatic_call_distributors_path(@tenant)
      if @automatic_call_distributor && !@automatic_call_distributor.new_record?
        add_breadcrumb @automatic_call_distributor, tenant_automatic_call_distributor_path(@tenant, @automatic_call_distributor)
      end
    end
  end
end
