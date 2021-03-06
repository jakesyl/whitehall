Feature: Announcing a upcoming statistics release

  As an publisher of government statistics
  I want to be able to announce upcoming statistics publications
  So that citizens can see which statistics publications are coming soon and when they will be published.

  Scenario: announcing an upcoming statistics publication
    Given I am a GDS editor in the organisation "Department for Beards"
    When I announce an upcoming statistics publication called "Monthly Beard Stats"
    Then I should see the announcement listed on the list of announcements

  Scenario: drafting a document from a statistics announcement
    Given I am a GDS editor in the organisation "Department for Beards"
    And a statistics announcement called "Monthly Beard Stats" exists
    When I draft a document from the announcement
    Then the document fields are pre-filled based on the announcement
    When I save the draft statistics document
    Then the document becomes linked to the announcement

  Scenario: changing the date on a statistics announcement
    Given I am a GDS editor in the organisation "Department for Beards"
    And a statistics announcement called "Monthly Beard Stats" exists
    When I change the release date on the announcement
    Then the new date is reflected on the announcement

  @javascript
  Scenario: linking a document to a statistics announcement
    Given I am a GDS editor in the organisation "Department for Beards"
    And a draft statistics publication called "Beard statistics - January 2014"
    And a statistics announcement called "January's beard statistics" exists
    When I link the announcement to the publication
    Then I should see that the announcement is linked to the publication
