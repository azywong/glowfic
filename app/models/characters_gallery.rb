class CharactersGallery < ActiveRecord::Base
  belongs_to :character
  belongs_to :gallery

  before_create :autofill_order
  after_destroy :reorder_others

  def reorder_others
    character.reorder_galleries
  end

  def autofill_order
    self.section_order = CharactersGallery.where(character_id: character_id).count
  end
end
