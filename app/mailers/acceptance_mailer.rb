class AcceptanceMailer < ActionMailer::Base
  default from: '"Beyond Z" <no-reply@beyondz.org>'

  def request_availability_confirmation(user)
    @user = user

    @confirm_link = user_confirm_url

    mail(to: user.email, subject: 'Please confirm your availability')
  end
end
