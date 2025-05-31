require 'rails_helper'
require 'rails/generators'

require_relative "#{Rails.root}/../../lib/generators/apache_age/scaffold_edge/scaffold_edge_generator"

# for this test unfortunately, dynamically creating the resources doesn't work
# before the test in: `spec/dummy` run:
# `bin/rails g apache_age:scaffold_node Dog name`
# `bin/rails g apache_age:scaffold_node Animals/Cat name`
# `bin/rails g apache_age:scaffold_edge HasDog role`
# `bin/rails g apache_age:scaffold_edge People/HasCat role`
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
RSpec.describe 'ScaffoldEdge', type: :system do
  context 'without a namespace' do
    let(:empty_list) {
      <<~EMPTY_LIST
      <h1>Has dogs</h1>

      <div id="has_dogs">
      </div>

      <a href="/has_dogs/new">New has dog</a>
      EMPTY_LIST
    }

    before do
      driven_by(:rack_test)
      Dog.create(name: 'Pema')
      Character.create(name: 'Bill')
    end

    it 'displays an empty list initially and then shows the newly created edge' do
      visit has_dogs_path
      expect(page.body).to include(empty_list)

      # Create a new Dog
      click_link 'New has dog'
      fill_in 'Role', with: 'Owner'
      select 'Bill (Character)', from: 'has_dog_start_id'
      select 'Pema (Dog)', from: 'has_dog_end_id'
      click_button 'Create Has dog'

      # redirected to show page with new dog
      expect(page).to have_content('Has dog was successfully created.')
      expect(page).to have_content('Role: Owner')
      expect(page).to have_content('Start-Node: Bill (Character)')
      expect(page).to have_content('End-Node: Pema (Dog)')

      # update
      click_link 'Edit this has dog'
      fill_in 'Role', with: 'Walker'
      click_button 'Update Has dog'

      # redirected to show page with updated name
      expect(page).to have_content('Has dog was successfully updated.')
      expect(page).to have_content('Role: Walker')

      # List
      click_link 'Back to has dogs'
      expect(page).to have_content('Has dogs')
      expect(page).to have_content('Role: Walker')

      click_link 'Show this has dog'
      click_button 'Destroy this has dog'

      expect(page).to have_content('Has dog was successfully destroyed.')
      expect(page).to have_content('Has dogs')
      expect(page).not_to have_content('Role')
      expect(page.body).to include(empty_list)
    end
  end

  context 'with a namespace' do
    # let(:node_name) { "Cat" }
    # let(:args) { [node_name, "name"] }
    # let(:destination_root) { File.expand_path("../../../spec/dummy", __FILE__) }
    # let(:config) { {behavior:, destination_root:} }
    let(:empty_list) {
      <<~EMPTY_LIST
      <h1>Has cats</h1>

      <div id="people_has_cats">
      </div>

      <a href="/people/has_cats/new">New has cat</a>
      EMPTY_LIST
    }

    before do
      driven_by(:rack_test)
      Animals::Cat.create(name: 'Shiné')
      Flintstones::Character.create(name: 'MarpoRi')
    end

    it 'displays an empty list initially and then shows the newly created edge' do
      visit people_has_cats_path
      expect(page.body).to include(empty_list)

      # Create a new Dog
      click_link 'New has cat'
      fill_in 'Role', with: 'Owner'
      select 'MarpoRi (Flintstones__Character)', from: 'people_has_cat_start_id'
      select 'Shiné (Animals__Cat)', from: 'people_has_cat_end_id'
      click_button 'Create Has cat'

      # redirected to show page with new dog
      expect(page).to have_content('Has cat was successfully created.')
      expect(page).to have_content('Role: Owner')
      expect(page).to have_content('Start-Node: MarpoRi (Flintstones__Character)')
      expect(page).to have_content('End-Node: Shiné (Animals__Cat)')

      # update
      click_link 'Edit this has cat'
      fill_in 'Role', with: 'Feeder'
      click_button 'Update Has cat'

      # redirected to show page with updated name
      expect(page).to have_content('Has cat was successfully updated.')
      expect(page).to have_content('Role: Feeder')

      # List
      click_link 'Back to has cats'
      expect(page).to have_content('Has cats')
      expect(page).to have_content('Role: Feeder')

      click_link 'Show this has cat'
      click_button 'Destroy this has cat'

      expect(page).to have_content('Has cat was successfully destroyed.')
      expect(page).to have_content('Has cats')
      expect(page).not_to have_content('Role')
      expect(page.body).to include(empty_list)
    end
  end
end
