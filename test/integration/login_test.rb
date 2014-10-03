require 'test_helper'

describe 'Login' do
  it 'should bring students to the assignments path upon success' do
    user = FactoryGirl.create(:user)
    user.confirm!
    visit(new_user_session_path)
    fill_in('Email', with: user.email)
    fill_in('Password', with: user.password)
    click_on 'Log in'

    current_path.must_equal(welcome_path)

    # I was randomly getting "email already taken" with the spec
    # syntax so I'm explicitly destroying the user when we're done
    # with it to ensure things are clean for the next test.
    user.destroy!
  end

  it 'should redirect you to the login page upon failure' do
    user = FactoryGirl.create(:user)
    user.confirm!
    visit new_user_session_path
    fill_in('Email', with: user.email)
    fill_in('Password', with: 'wrong')
    click_on 'Log in'

    current_path.must_equal(new_user_session_path)

    user.destroy!
  end
end
