class Admin::TaskDefinitionsController < Admin::ApplicationController
  def index
    @task_definitions = TaskDefinition.all
  end

  def show
    redirect_to edit_admin_task_definition_path(params[:id])
  end

  def edit
    @task_definition = TaskDefinition.find(params[:id])
  end

  def update
    td_new = params[:task_definition]
    td = TaskDefinition.find(params[:id])
    td.name = td_new[:name]
    td.details = td_new[:details]
    td.save
    redirect_to edit_admin_task_definition_path(params[:id])
  end
end
