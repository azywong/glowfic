class CharacterAlias < ActiveRecord::Base
  belongs_to :character
  validates_presence_of :character, :name
  after_destroy :clear_alias_ids

  def as_json(options={})
    { id: id, name: name }
  end

  private

  def clear_alias_ids
    Reply.where(character_alias_id: id).update_all(character_alias_id: nil)
    Post.where(character_alias_id: id).update_all(character_alias_id: nil)
  end
end
