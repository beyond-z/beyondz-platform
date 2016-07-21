require 'doc_ripper'
class Admin::ResumesController < ApplicationController
  def index
    page = params[:page]
    if params[:search]
      @resumes = Resume.fulltext_search(params[:search]).page(page)
    else
      @resumes = Resume.search(params[:tag]).page(page)
    end
  end

  def new
  end

  def create
    r = Resume.create(params.require(:resume).permit!)
    r.save!

    uploaded_file = params[:resume][:resume].original_filename

    r.content =
      case File.extname(uploaded_file)
      when '.docx'
        # DocRipper::rip(params[:resume][:resume].path())
        # the rip doesn't work because the path sliced off the extension
        # so i just copy/pasted the implementation from there to here.
        `unzip -p #{Shellwords.escape(params[:resume][:resume].path)} | grep '<w:t' | sed 's/<[^<]*>//g' | grep -v '^[[:space:]]*$'`
      when '.doc'
        text = ''
        MSWordDoc::Extractor.load(params[:resume][:resume].path) do |doc|
          text = doc.whole_contents
        end
        text
      when '.txt'
        params[:resume][:resume].read
      else
        ''
      end

    r.save!
    redirect_to admin_resumes_path
  end

  def update
  end
end
