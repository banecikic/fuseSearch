require 'test_helper'

class AddPasswordGroupTest < ActionDispatch::IntegrationTest
  test 'create valid password groups' do

    # test page layout
    visit(root_path)

    
    click_button('Add')
    assert(has_button?('Add', :visible => false))

    # test form layout
    
    assert(has_link?('Add group'))

    click_link('Add group')
    assert(page.has_css?('form'), :count => 1)

    data = get_random_password_group_name

    page.fill_in('name', :with => data[1])
    

    click_button('Create Password group')
 
  end

end
