module EnrollmentsHelper
  def graduation_years
    Time.now.year + 1 .. Time.now.year + 5
  end
end
