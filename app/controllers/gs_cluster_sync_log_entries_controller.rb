class GsClusterSyncLogEntriesController < ApplicationController

  # GET /gs_cluster_sync_log_entries/new.json
  def new
    @gs_cluster_sync_log_entry = GsClusterSyncLogEntry.new

    respond_to do |format|
      format.json { render json: @gs_cluster_sync_log_entry }
    end
  end

  # POST /gs_cluster_sync_log_entries.json
  def create
    @gs_cluster_sync_log_entry = GsClusterSyncLogEntry.new(params[:gs_cluster_sync_log_entry])

    respond_to do |format|
      if @gs_cluster_sync_log_entry.save
        format.json { render json: @gs_cluster_sync_log_entry, status: :created, location: @gs_cluster_sync_log_entry }
      else
        format.json { render json: @gs_cluster_sync_log_entry.errors, status: :unprocessable_entity }
      end
    end
  end

end
