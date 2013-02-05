class BackupJobsController < ApplicationController
  def index
    @backup_jobs = BackupJob.all
  end

  def show
    @backup_job = BackupJob.find(params[:id])
  end

  def new
    @backup_job = BackupJob.new
  end

  def create
#    @backup_job = BackupJob.new(params[:backup_job])
    @backup_job = BackupJob.new(:started_at => Time.now)

    if @backup_job.save
      redirect_to @backup_job, :notice => t('backup_jobs.controller.successfuly_created')
    else
      render :new
    end
  end

  # def edit
  #   @backup_job = BackupJob.find(params[:id])
  # end

  # def update
  #   @backup_job = BackupJob.find(params[:id])
  #   if @backup_job.update_attributes(params[:backup_job])
  #     redirect_to @backup_job, :notice  => t('backup_jobs.controller.successfuly_updated')
  #   else
  #     render :edit
  #   end
  # end

  def destroy
    @backup_job = BackupJob.find(params[:id])
    @backup_job.destroy
    redirect_to backup_jobs_url, :notice => t('backup_jobs.controller.successfuly_destroyed')
  end
end
