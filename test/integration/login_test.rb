require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest
  test 'Login successfully' do
    user = FactoryGirl::create(:user)
    user.confirm!

    visit(new_user_session_path)
    fill_in('Email', :with => user.email)
    fill_in('Password', :with => user.password)
    click_on 'Sign in'

    # Logged in students should end up at the assignments path
    assert current_path == assignments_path
  end

  test 'Login failure when not confirmed' do
    user = FactoryGirl::create(:user)

    visit(new_user_session_path)
    fill_in('Email', :with => user.email)
    fill_in('Password', :with => user.password)
    click_on 'Sign in'

    # We should still be on the page
    assert current_path == new_user_session_path

    assert page.has_content?('You have to confirm your account before continuing.')
  end

  test 'Login failure' do
    user = FactoryGirl::create(:user)
    user.confirm!

    visit(new_user_session_path)
    fill_in('Email', :with => user.email)
    fill_in('Password', :with => 'wrong')
    click_on 'Sign in'

    # We should still be on the page
    assert current_path == new_user_session_path

    assert page.has_content?('Invalid email or password.')

  end

  # This test is meant to exercise the controller directly to ensure
  # the expected failure actually fails - this basically tests the tests
  test 'Login failure sanity test' do
    user = FactoryGirl::create(:user)
    post new_user_session_path, :user => {:email => user.email, :password => 'wrong' }
    # Log in failure means they have to try again, so we should still be here
    assert_equal new_user_session_path, path
    assert_equal 'Invalid email or password.', flash[:alert]
  end

end
