require "spec_helper"

RSpec.describe Api::V1::BoardsController do
  describe "GET show" do
    it "requires valid board", :show_in_doc do
      get :show, id: 0
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Continuity could not be found.")
    end

    it "succeeds with valid board" do
      board = create(:board)
      section1 = create(:board_section, board: board)
      section2 = create(:board_section, board: board)
      get :show, id: board.id
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(board.id)
      expect(response.json['board_sections'].size).to eq(2)
      expect(response.json['board_sections'][0]['id']).to eq(section1.id)
      expect(response.json['board_sections'][1]['id']).to eq(section2.id)
    end

    it "succeeds for logged in users with valid board" do
      login
      board = create(:board)
      section1 = create(:board_section, board: board)
      section2 = create(:board_section, board: board)
      get :show, id: board.id
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(board.id)
      expect(response.json['board_sections'].size).to eq(2)
      expect(response.json['board_sections'][0]['id']).to eq(section1.id)
      expect(response.json['board_sections'][1]['id']).to eq(section2.id)
    end

    it "orders sections by section_order", :show_in_doc do
      board = create(:board)
      section1 = create(:board_section, board: board)
      section2 = create(:board_section, board: board)
      section1.section_order = 1
      section1.save
      section2.section_order = 0
      section2.save
      get :show, id: board.id
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(board.id)
      expect(response.json['board_sections'].size).to eq(2)
      expect(response.json['board_sections'][0]['id']).to eq(section2.id)
      expect(response.json['board_sections'][0]['order']).to eq(0)
      expect(response.json['board_sections'][1]['id']).to eq(section1.id)
      expect(response.json['board_sections'][1]['order']).to eq(1)
    end
  end
end
