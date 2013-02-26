class RestoreJobsController < ApplicationController
  skip_before_filter :start_setup_if_new_installation, :only => [:new, :create, :show, :index]

  load_and_authorize_resource :restore_job

  def index
  end

  def show
  end

  def new
  end

  def create
    @restore_job.state = 'new'

    if @restore_job.save
      session[:user_id] = nil
      redirect_to @restore_job, :notice => t('restore_jobs.controller.successfuly_created')
    else
      render :new
    end
  end
end
