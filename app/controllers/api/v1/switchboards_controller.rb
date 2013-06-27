module Api
  module V1
    class SwitchboardsController < ApplicationController
      respond_to :json

      def index
        @user = current_user
        @switchboards = Switchboard.all

        if can? :read, @switchboards
          respond_with @switchboards
        end
      end

      def show
        @user = current_user
        @switchboard = Switchboard.find(params[:id])

        if can? :read, @switchboard
          respond_with @switchboard
        end
      end
    end
  end
end
