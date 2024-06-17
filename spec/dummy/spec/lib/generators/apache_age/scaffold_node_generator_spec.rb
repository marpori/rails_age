require 'rails_helper'
require 'rails/generators'

require_relative "#{Rails.root}/../../lib/generators/apache_age/scaffold_node/scaffold_node_generator"

# for this test unfortunately, dynamically creating the resources doesn't work
# before the test in: `spec/dummy` run:
# `bin/rails g apache_age:scaffold_node Dog name`
# `bin/rails g apache_age:scaffold_node Animals/Cat name`
# couldn't get the generator to work within the test runtime.
# let(:node_name) { "Pet" }
# let(:args) { [node_name, "name"] }
# let(:destination_root) { File.expand_path("../../../spec/dummy", __FILE__) }
# let(:config) { {behavior:, destination_root:} }
# before do
#   driven_by(:rack_test)
#   ApacheAge::ScaffoldNodeGenerator.start(args, {behavior: :invoke})
#   # ActiveSupport::Dependencies.clear
#   Rails.application.reloader.reload!
#   Rails.application.reload_routes!
# end
# after do
#   ApacheAge::ScaffoldNodeGenerator.start([node_name], {behavior: :revoke})
#   # ActiveSupport::Dependencies.clear
#   Rails.application.reloader.reload!
#   Rails.application.reload_routes!
# end
RSpec.describe 'ScaffoldNode', type: :system do
  context 'without a namespace' do
    let(:empty_list) {
      <<~EMPTY_LIST
      <h1>Dogs</h1>

      <div id="dogs">
      </div>

      <a href="/dogs/new">New dog</a>
      EMPTY_LIST
    }

    before { driven_by(:rack_test) }

    it 'displays an empty list initially and then shows the newly created post' do
      visit dogs_path
      expect(page.body).to include(empty_list)

      # Create a new Dog
      click_link 'New dog'
      fill_in 'Name', with: 'Pema'
      click_button 'Create Dog'

      # redirected to show page with new dog
      expect(page).to have_content('Dog was successfully created.')
      expect(page).to have_content('Name: Pema')

      # update
      click_link 'Edit this dog'
      fill_in 'Name', with: 'Nyima'
      click_button 'Update Dog'

      # redirected to show page with updated name
      expect(page).to have_content('Dog was successfully updated.')
      expect(page).to have_content('Name: Nyima')

      # List
      click_link 'Back to dogs'
      expect(page).to have_content('Dogs')
      expect(page).to have_content('Name: Nyima')

      click_link 'Show this dog'
      click_button 'Destroy this dog'

      expect(page).to have_content('Dog was successfully destroyed.')
      expect(page).to have_content('Dogs')
      expect(page).not_to have_content('Name')
    end
  end

  context 'with a namespace' do
    # let(:node_name) { "Cat" }
    # let(:args) { [node_name, "name"] }
    # let(:destination_root) { File.expand_path("../../../spec/dummy", __FILE__) }
    # let(:config) { {behavior:, destination_root:} }
    let(:empty_list) {
      <<~EMPTY_LIST
      <h1>Cats</h1>

      <div id="animals_cats">
      </div>

      <a href="/animals/cats/new">New cat</a>
      EMPTY_LIST
    }

    before { driven_by(:rack_test) }

    it 'displays an empty list initially and then shows the newly created post' do
      visit animals_cats_path
      expect(page.body).to include(empty_list)

      # Create a new Dog
      click_link 'New cat'
      fill_in 'Name', with: 'Pema'
      click_button 'Create Cat'

      # redirected to show page with new dog
      expect(page).to have_content('Cat was successfully created.')
      expect(page).to have_content('Name: Pema')

      # update
      click_link 'Edit this cat'
      fill_in 'Name', with: 'Nyima'
      click_button 'Update Cat'

      # redirected to show page with updated name
      expect(page).to have_content('Cat was successfully updated.')
      expect(page).to have_content('Name: Nyima')

      # List
      click_link 'Back to cats'
      expect(page).to have_content('Cats')
      expect(page).to have_content('Name: Nyima')

      click_link 'Show this cat'
      click_button 'Destroy this cat'

      expect(page).to have_content('Cat was successfully destroyed.')
      expect(page).to have_content('Cats')
      expect(page).not_to have_content('Name')
    end
  end
end
