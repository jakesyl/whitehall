require "test_helper"

class WorldwideOrganisationsControllerTest < ActionController::TestCase
  should_be_a_public_facing_controller

  test "shows worldwide organisation information" do
    organisation = create(:worldwide_organisation)
    get :show, id: organisation.id
    assert_equal organisation, assigns(:worldwide_organisation)
  end

  test "sets meta description" do
    organisation = create(:worldwide_organisation, summary: 'my summary')

    get :show, id: organisation.id

    assert_equal 'my summary', assigns(:meta_description)
  end

  test "should populate slimmer organisations header with worldwide organisation and its sponsored organisations" do
    organisation = create(:worldwide_organisation, :translated, :with_sponsorships)
    sponsoring_organisation = organisation.sponsoring_organisations.first

    get :show, id: organisation.id

    expected_header_value = "<#{organisation.analytics_identifier}><#{sponsoring_organisation.analytics_identifier}>"
    assert_equal expected_header_value, response.headers["X-Slimmer-Organisations"]
  end

  test "should set slimmer worldwide locations header" do
    world_location = create(:world_location)
    organisation = create(:worldwide_organisation, world_locations: [world_location])

    get :show, id: organisation.id

    assert_equal "<#{world_location.analytics_identifier}>", response.headers["X-Slimmer-World-Locations"]
  end

  view_test "shows links to associated world locations" do
    location_1 = create(:world_location)
    location_2 = create(:world_location)
    organisation = create(:worldwide_organisation, world_locations: [location_1, location_2])

    get :show, id: organisation.id

    assert_select "a[href='#{world_location_path(location_1)}']"
    assert_select "a[href='#{world_location_path(location_2)}']"
  end

  test "show redirects to the api worldwide organisation endpoint when json is requested" do
    organisation = create(:worldwide_organisation)
    get :show, id: organisation.id, format: :json
    assert_redirected_to api_worldwide_organisation_path(organisation, format: :json)
  end

  view_test "showing an organisation without a list of contacts doesn't try to create one" do
    # needs to be a view_test so the entire view is rendered
    worldwide_organisation = create(:worldwide_organisation)
    worldwide_organisation.main_office = create(:worldwide_office, worldwide_organisation: worldwide_organisation)
    get :show, id: worldwide_organisation

    worldwide_organisation.reload
    refute worldwide_organisation.has_home_page_offices_list?
  end

end
