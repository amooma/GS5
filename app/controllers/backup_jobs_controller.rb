class BackupJobsController < ApplicationController
  load_and_authorize_resource :backup_job

  before_filter :spread_breadcrumbs

  def index
    # @backup_jobs = BackupJob.all
  end

  def show
    # @backup_job = BackupJob.find(params[:id])
  end

  def new
    @backup_job = BackupJob.new
  end

  def create
    @backup_job = BackupJob.new(:started_at => Time.now)

    if @backup_job.save
      redirect_to @backup_job, :notice => t('backup_jobs.controller.successfuly_created')
    else
      render :new
    end
  end

  def destroy
    # @backup_job = BackupJob.find(params[:id])
    @backup_job.destroy
    redirect_to backup_jobs_url, :notice => t('backup_jobs.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    add_breadcrumb t("backup_jobs.index.page_title"), backup_jobs_path
    if @backup_job && !@backup_job.new_record?
      add_breadcrumb @backup_job, @backup_job
    end
  end  
end
