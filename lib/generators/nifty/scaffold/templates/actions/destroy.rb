  def destroy
    @<%= instance_name %> = <%= class_name %>.find(params[:id])
    @<%= instance_name %>.destroy
    redirect_to <%= items_url %>, :notice => t('<%= plural_name %>.controller.successfuly_destroyed')
  end
