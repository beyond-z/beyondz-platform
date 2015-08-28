class Admin::AssignmentDefinitionsController < Admin::ApplicationController
  def index
    @assignment_definitions = AssignmentDefinition.all
  end

  def show
    redirect_to edit_admin_assignment_definition_path(params[:id])
  end

  def edit
    @assignment_definition = AssignmentDefinition.find(params[:id])
  end

  def update
    ad_new = params[:assignment_definition]
    ad = AssignmentDefinition.find(params[:id])
    ad.title = ad_new[:title]
    ad.front_page_info = ad_new[:front_page_info]
    ad.save
    redirect_to edit_admin_assignment_definition_path(params[:id])
  end
end
