class GuiFunctionsController < ApplicationController
  load_resource :gui_function

  before_filter :load_user_groups
  before_filter :spread_breadcrumbs

  def index
    @gui_functions = GuiFunction.order(:category, :name)
  end

  def show
    @gui_function = GuiFunction.find(params[:id])
  end

  def new
    @gui_function = GuiFunction.new

    @user_groups.each do |user_group|
      if @gui_function.user_groups.where(:id => user_group.id).count == 0
        @gui_function.gui_function_memberships.build(:user_group_id => user_group.id, :activated => true)
      end
    end
  end

  def create
    @gui_function = GuiFunction.new(params[:gui_function])

    if @gui_function.save
      redirect_to @gui_function, :notice => t('gui_functions.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @gui_function = GuiFunction.find(params[:id])
    @user_groups.each do |user_group|
      if @gui_function.user_groups.where(:id => user_group.id).count == 0
        @gui_function.gui_function_memberships.build(:user_group_id => user_group.id, :activated => true)
      end
    end
  end

  def update
    @gui_function = GuiFunction.find(params[:id])
    if @gui_function.update_attributes(params[:gui_function])
      redirect_to @gui_function, :notice  => t('gui_functions.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @gui_function = GuiFunction.find(params[:id])
    @gui_function.destroy
    redirect_to gui_functions_url, :notice => t('gui_functions.controller.successfuly_destroyed')
  end

  private
  def load_user_groups
    @user_groups = Tenant.find(current_user.current_tenant).user_groups.order(:position)
  end

  def spread_breadcrumbs
    add_breadcrumb t("gui_functions.index.page_title"), gui_functions_path
    if @gui_function && !@gui_function.new_record?
      add_breadcrumb @gui_function, gui_function_path(@gui_function)
    end
  end

end
