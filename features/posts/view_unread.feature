Feature: View Unread Posts
As a reader
I want to be able to see a list of unread posts
So that I can read the most relevant glowfic

Scenario: Logged out user cannot access
When I view my unread posts
Then I should see "You must be logged in"
And I should not see "Unread Posts"

Scenario: Viewing all unread
Given I am logged in
And I have 2 unread posts
When I view my unread posts
Then I should see "Unread Posts"

Scenario: Dark layout uses appropriate images
Given I am logged in
And my account uses the starry dark layout
And I have 2 unread posts
When I view my unread posts
Then I should see the bullet icon
And I should not see the note icon
