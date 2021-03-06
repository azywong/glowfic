require "spec_helper"

RSpec.describe Tag do
  describe "#merge_with" do
    it "takes the correct actions" do
      good_tag = create(:tag)
      bad_tag = create(:tag)

      # TODO handle properly with nested attributes
      create(:post, tag_ids: [good_tag.id], setting_ids: [], warning_ids: [])
      create(:post, tag_ids: [good_tag.id], setting_ids: [], warning_ids: [])
      create(:post, tag_ids: [good_tag.id], setting_ids: [], warning_ids: [])
      create(:post, tag_ids: [bad_tag.id], setting_ids: [], warning_ids: [])
      create(:post, tag_ids: [bad_tag.id], setting_ids: [], warning_ids: [])

      expect(good_tag.posts.count).to eq(3)
      expect(bad_tag.posts.count).to eq(2)

      good_tag.merge_with(bad_tag)

      expect(Tag.find_by_id(bad_tag.id)).to be_nil
      expect(bad_tag.posts.count).to eq(0)
      expect(good_tag.posts.count).to eq(5)
    end
  end

  describe "validations" do
    it "requires unique name" do
      tag = create(:tag)
      new_tag = build(:tag, name: tag.name)
      expect(new_tag).not_to be_valid
    end

    it "requires unique case sensitive name" do
      tag = create(:tag, name: 'CASE')
      new_tag = build(:tag, name: tag.name.downcase)
      expect(new_tag).not_to be_valid
    end
  end
end
