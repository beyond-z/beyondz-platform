class ResumesController < ApplicationController
  def index
    page = params[:page]
    if params[:search]
      @resumes = Resume.fulltext_search(params[:search]).page(page)
    else
      @resumes = Resume.search(params[:tag]).page(page)
    end
  end
end
