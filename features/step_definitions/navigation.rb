Given(/^I am logged in$/) do
  user = create(:user, password: 'secret')
  visit root_path
  fill_in "username", with: user.username
  fill_in "password", with: 'secret'
  click_button "Log in"
end

Given(/^I have (\d) galleryless icons?$/) do |num|
  num.to_i.times do create(:icon, user: User.last) end
end

Given(/^I have (\d) unread posts?$/) do |num|
  num.to_i.times do
    unread = create(:post)
    unread.mark_read(User.first, Time.now - 1.day)
    create(:reply, user: unread.user, post: unread)
  end
end

Given(/^my account uses the (.+) layout$/) do |layout|
  layout_name = layout.gsub(" ", "")
  user = User.last
  user.layout = layout_name
  user.save!
end

When(/^I start a new post$/) do
  visit new_post_path
end

When(/^I go to create a new character$/) do
  visit new_character_path
end

When(/^I view my unread posts$/) do
  visit unread_posts_path
end

Then(/^I should see "(.*)"$/) do |content|
  expect(page).to have_content(content)
end

Then(/^I should not see "(.*)"$/) do |content|
  expect(page).not_to have_content(content)
end
