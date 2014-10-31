require 'test_helper'

describe 'Login' do
  # We no longer do most login tasks here, instead option for the SSO
  # server, so the only test is to ensure the fallback still works
  it 'should bring students to the assignments path upon success' do
    user = FactoryGirl.create(:user)
    user.confirm!
    visit(new_user_session_path('plain_login' => 1))
    fill_in('Email', with: user.email)
    fill_in('Password', with: user.password)
    click_on 'Log in'

    current_path.must_equal(welcome_path)

    # I was randomly getting "email already taken" with the spec
    # syntax so I'm explicitly destroying the user when we're done
    # with it to ensure things are clean for the next test.
    user.destroy!
  end
end
