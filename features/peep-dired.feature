Feature: Looking up the contents of a file

  Scenario: Peeping contents of the files in a dired buffer
    Given I open dired buffer in the root directory
    And I place cursor on "peep-dired.el" file
    And I run command "peep-dired"
    Then I should see "peep-dired.el" buffer in other window
    When I go down
    Then I should see "" buffer in other window
    When I go up
    When I go up
    When I press "<down>"
    Then I should scroll down buffer in other window
    When I press "<up>"
    Then I should scroll up buffer in other window
