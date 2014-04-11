require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "login" do
    expected = users(:one)
    assert_equal expected.id, User.login("test@example.org", "test")

    assert_raises(LoginException) do
      # bad username
      User.login("nonexistent@example.org", "test")
    end
    assert_raises(LoginException) do
      # bad password
      User.login("test@example.org", "Test")
    end
  end
end
