module UsersHelper
  def graduation_years
    Time.now.year .. Time.now.year + 10
  end

  def started_college_years
    Time.now.year - 10 .. Time.now.year
  end
end
