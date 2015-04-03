module UsersHelper
  def graduation_years
    Time.now.year .. Time.now.year + 7
  end

  def started_college_years
    Time.now.year - 7 .. Time.now.year
  end
end
