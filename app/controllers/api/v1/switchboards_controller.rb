module Api
  module V1
    class SwitchboardsController < ApplicationController
      respond_to :json

      def index
        @user = current_user
        @switchboards = @user.switchboards

        respond_with @switchboards
      end

      def show
        @user = current_user
        @switchboard = @user.switchboards.find(params[:id])

        respond_with @switchboard
      end
    end
  end
end
