class GsParametersController < ApplicationController
  # GET /gs_parameters
  # GET /gs_parameters.json
  def index
    @gs_parameters = GsParameter.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @gs_parameters }
    end
  end

  # GET /gs_parameters/1
  # GET /gs_parameters/1.json
  def show
    @gs_parameter = GsParameter.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @gs_parameter }
    end
  end

  # GET /gs_parameters/new
  # GET /gs_parameters/new.json
  def new
    @gs_parameter = GsParameter.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @gs_parameter }
    end
  end

  # GET /gs_parameters/1/edit
  def edit
    @gs_parameter = GsParameter.find(params[:id])
  end

  # POST /gs_parameters
  # POST /gs_parameters.json
  def create
    @gs_parameter = GsParameter.new(params[:gs_parameter])

    respond_to do |format|
      if @gs_parameter.save
        format.html { redirect_to @gs_parameter, notice: 'Gs parameter was successfully created.' }
        format.json { render json: @gs_parameter, status: :created, location: @gs_parameter }
      else
        format.html { render action: "new" }
        format.json { render json: @gs_parameter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /gs_parameters/1
  # PUT /gs_parameters/1.json
  def update
    @gs_parameter = GsParameter.find(params[:id])

    respond_to do |format|
      if @gs_parameter.update_attributes(params[:gs_parameter])
        format.html { redirect_to @gs_parameter, notice: 'Gs parameter was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @gs_parameter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gs_parameters/1
  # DELETE /gs_parameters/1.json
  def destroy
    @gs_parameter = GsParameter.find(params[:id])
    @gs_parameter.destroy

    respond_to do |format|
      format.html { redirect_to gs_parameters_url }
      format.json { head :no_content }
    end
  end
end
