module Api
  module V1
    class SwitchboardEntriesController < ApplicationController
      respond_to :json

      def index
        if params[:ids]
          @switchboard_entries = SwitchboardEntry.where(:id => params[:ids])
        else
          @switchboard_entries = SwitchboardEntry.all
        end

        respond_with @switchboard_entries
      end

      def show
        @switchboard_entry = SwitchboardEntry.find(params[:id])

        respond_with @switchboard_entry
      end  
    end
  end
end