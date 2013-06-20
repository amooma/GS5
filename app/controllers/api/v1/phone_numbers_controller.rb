module Api
  module V1
    class PhoneNumbersController < ApplicationController
      respond_to :json

      def index
        if params[:ids]
          @phone_numbers = PhoneNumber.where(:id => params[:ids])
        else
          @phone_numbers = PhoneNumber.all
        end

        respond_with @phone_numbers
      end

      def show
        @phone_number = PhoneNumber.find(params[:id])

        respond_with @phone_number
      end  
    end
  end
end
