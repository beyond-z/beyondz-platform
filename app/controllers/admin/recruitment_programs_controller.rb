
class Admin::RecruitmentProgramsController < Admin::ApplicationController
  def index
    @programs = RecruitmentProgram.all
  end

  def create
    rp = RecruitmentProgram.create(params[:recruitment_program].permit(:name, :campaign_id))
    redirect_to("/admin/recruitment_programs/#{rp.id}")
  end

  def update
    @program = RecruitmentProgram.find(params[:id])
    @program.name = params[:recruitment_program][:name]
    @program.campaign_id = params[:recruitment_program][:campaign_id]
    @program.save
    redirect_to("/admin/recruitment_programs/#{@program.id}")
  end

  def new
    @program = RecruitmentProgram.new
  end

  def show
    @program = RecruitmentProgram.find(params[:id])
  end

  def edit
    @program = RecruitmentProgram.find(params[:id])
  end

  def destroy
    @program = RecruitmentProgram.find(params[:id])
    @program.destroy!
    redirect_to("/admin/recruitment_programs")
  end
end
