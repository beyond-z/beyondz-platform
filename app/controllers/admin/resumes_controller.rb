class Admin::ResumesController < ApplicationController
  def index
    page = params[:page]
    @resumes = Resume.search(params[:search]).page(page)
  end

  def new
  end

  def create
    r = Resume.create(params.require(:resume).permit!)
    r.save!
    redirect_to admin_resumes_path
  end

  def update
  end
end
