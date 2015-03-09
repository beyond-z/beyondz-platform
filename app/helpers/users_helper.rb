module UsersHelper
  def graduation_years
    Time.now.year + 1 .. Time.now.year + 5
  end

  def started_college_years
    Time.now.year - 5 .. Time.now.year
  end
end
