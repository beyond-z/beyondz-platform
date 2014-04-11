require 'test_helper'

class NotificationsTest < ActionMailer::TestCase
  test "forgot_password" do
    mail = Notifications.forgot_password("to@example.org", "Test", "#")
    assert_equal "Forgot password", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["no-reply@beyondz.org"], mail.from
    #assert_match "Hi", mail.body.encoded
  end

end
