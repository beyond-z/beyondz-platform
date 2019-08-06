require 'rails_helper'

RSpec.describe User, type: 'model' do
	describe '#capitalize_name' do
		context 'when there is something to capitalize' do
			let (:user) { User.new(first_name: 'john rogers', last_name: 'deere green') }
			
			it 'capitalizes the first letter of parts of first name' do
				allow(user).to receive(:first_name_changed?).and_return(true)
				user.capitalize_name
				expect(user.first_name).to eq('John Rogers')
			end

			it 'capitalizes the first letter of parts of last name' do
				allow(user).to receive(:last_name_changed?).and_return(true)
				user.capitalize_name
				expect(user.last_name).to eq('Deere Green')
			end
		end

		context 'when parts of the name are nil' do
			let (:user) { User.new(first_name: nil, last_name: nil) }
			
			it 'handles when first name is nil' do
				allow(user).to receive(:first_name_changed?).and_return(true)
				user.capitalize_name
				expect(user.first_name).to be_nil
			end

			it 'handles when last name is nil' do
				allow(user).to receive(:last_name_changed?).and_return(true)
				user.capitalize_name
				expect(user.last_name).to be_nil
			end
		end

	end
end