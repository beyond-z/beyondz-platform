class Admin::ListsController < Admin::ApplicationController
  def show
    if params[:id]
      @list = List.find_by_friendly_name(params[:id])
    end
    if @list.nil?
      @list = List.new
      @list.friendly_name = params[:id]
    end
  end

  def update
    list = List.find_by_friendly_name(params[:list][:friendly_name])
    list.content = params[:list][:content]
    list.save!
    flash[:message] = 'List saved.'
    redirect_to admin_root_path
  end

  def create
    List.create(
      :friendly_name => params[:list][:friendly_name],
      :content => params[:list][:content])
    flash[:message] = 'List saved.'
    redirect_to admin_root_path
  end
end
