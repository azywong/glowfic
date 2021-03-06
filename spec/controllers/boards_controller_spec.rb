require "spec_helper"

RSpec.describe BoardsController do
  describe "GET index" do
    context "without a user_id" do
      it "succeeds when logged out" do
        get :index
        expect(response.status).to eq(200)
      end

      it "succeeds when logged in" do
        login
        get :index
        expect(response.status).to eq(200)
      end

      it "sets correct variables" do
        user = create(:user)
        board1 = create(:board, creator_id: user.id)
        board2 = create(:board, creator_id: user.id)

        get :index
        expect(assigns(:boards)).to match_array([board1, board2])
        expect(assigns(:page_title)).to eq('Continuities')
      end
    end

    context "with a user_id" do
      it "does not require login" do
        user = create(:user)
        get :index, user_id: user.id
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:page_title)).to eq("#{user.username}'s Continuities")
      end

      it "defaults to current user if user id invalid" do
        user = create(:user)
        login_as(user)
        get :index, user_id: -1
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:page_title)).to eq('Your Continuities')
      end

      it "displays error if user id invalid and logged out" do
        get :index, user_id: -1
        expect(flash[:error]).to eq('User could not be found.')
        expect(response).to redirect_to(root_url)
      end

      it "sets correct variables" do
        user = create(:user)
        owned_board = create(:board, creator_id: user.id)

        get :index, user_id: user.id
        expect(assigns(:boards)).to match_array([owned_board])

        coauthor = create(:user)
        owned_board2 = create(:board, creator_id: user.id)
        owned_board2.coauthors << coauthor
        owned_board3 = create(:board, creator_id: user.id)
        owned_board3.cameos << coauthor

        get :index, user_id: coauthor.id
        expect(assigns(:boards)).to match_array([owned_board2])
        expect(assigns(:cameo_boards)).to match_array([owned_board3])
      end
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :new
      expect(response.status).to eq(200)
    end

    it "sets correct variables" do
      user_id = login
      current_user = User.find(user_id)
      other_users = 3.times.collect do create(:user) end

      get :new

      expect(assigns(:board)).to be_an_instance_of(Board)
      expect(assigns(:board)).to be_a_new_record
      expect(assigns(:board).creator_id).to eq(user_id)
      expect(assigns(:page_title)).to eq("New Continuity")

      expect(assigns(:authors).size).to eq(3)
      expect(assigns(:authors)).to match_array(other_users)
      expect(assigns(:authors)).not_to include(current_user)
      expect(assigns(:authors).sort_by(&:username)).to eq(assigns(:authors))

      expect(assigns(:cameos).size).to eq(3)
      expect(assigns(:cameos)).to match_array(other_users)
      expect(assigns(:cameos)).not_to include(current_user)
      expect(assigns(:cameos).sort_by(&:username)).to eq(assigns(:cameos))
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Continuity could not be created.")
      expect(flash[:error][:array]).to be_present
      expect(response).to render_template('new')
    end

    it "sets correct variables on failure" do
      login
      other_users = 3.times.collect do create(:user) end

      post :create

      expect(assigns(:board)).to be_an_instance_of(Board)
      expect(assigns(:board)).to be_a_new_record
      expect(assigns(:board)).not_to be_valid
      expect(assigns(:board).creator).to eq(assigns(:current_user))
      expect(assigns(:page_title)).to eq("New Continuity")

      expect(assigns(:authors).size).to eq(3)
      expect(assigns(:authors)).to match_array(other_users)
      expect(assigns(:authors)).not_to include(assigns(:current_user))
      expect(assigns(:authors).sort_by(&:username)).to eq(assigns(:authors))

      expect(assigns(:cameos).size).to eq(3)
      expect(assigns(:cameos)).to match_array(other_users)
      expect(assigns(:cameos)).not_to include(assigns(:current_user))
      expect(assigns(:cameos).sort_by(&:username)).to eq(assigns(:cameos))
    end

    it "successfully makes a board" do
      expect(Board.count).to eq(0)
      login
      post :create, board: {name: 'TestCreateBoard'}
      expect(response).to redirect_to(boards_url)
      expect(flash[:success]).to eq("Continuity created!")
      expect(Board.count).to eq(1)
      expect(Board.first.name).to eq('TestCreateBoard')
      expect(Board.first.creator).to eq(assigns(:current_user))
    end
  end

  describe "GET show" do
    it "requires valid board" do
      get :show, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "succeeds with valid board" do
      board = create(:board)
      get :show, id: board.id
      expect(response.status).to eq(200)
    end

    it "succeeds for logged in users with valid board" do
      login
      board = create(:board)
      get :show, id: board.id
      expect(response.status).to eq(200)
    end

    it "only fetches the board's first 25 posts" do
      board = create(:board)
      26.times do create(:post, board: board) end
      get :show, id: board.id
      expect(assigns(:posts).size).to eq(25)
    end

    it "orders the posts by updated_at" do
      board = create(:board)
      3.times do create(:post, board: board, tagged_at: Time.now + rand(5..30).hours) end
      get :show, id: board.id
      expect(assigns(:posts)).to eq(assigns(:posts).sort_by(&:tagged_at).reverse)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid board" do
      login
      get :edit, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires board permission" do
      user = create(:user)
      login_as(user)
      board = create(:board)
      expect(board).not_to be_editable_by(user)
      get :edit, id: board.id
      expect(response).to redirect_to(board_url(board))
      expect(flash[:error]).to eq("You do not have permission to edit that continuity.")
    end

    it "succeeds with valid board" do
      board = create(:board)
      login_as(board.creator)
      get :edit, id: board.id
      expect(response.status).to eq(200)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid board" do
      login
      put :update, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires board permission" do
      user = create(:user)
      login_as(user)
      board = create(:board)
      expect(board).not_to be_editable_by(user)
      put :update, id: board.id
      expect(response).to redirect_to(board_url(board))
      expect(flash[:error]).to eq("You do not have permission to edit that continuity.")
    end

    it "requires valid params" do
      user = create(:user)
      board = create(:board, creator: user)
      login_as(user)
      put :update, id: board.id, board: {name: ''}
      expect(response).to render_template('edit')
      expect(flash[:error][:message]).to eq("Continuity could not be created.")
      expect(flash[:error][:array]).to be_present
    end

    it "succeeds" do
      user = create(:user)
      board = create(:board, creator: user)
      name = board.name
      login_as(user)
      put :update, id: board.id, board: {name: name + 'edit'}
      expect(response).to redirect_to(board_url(board))
      expect(flash[:success]).to eq("Continuity saved!")
      expect(board.reload.name).to eq(name + 'edit')
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid board" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires board permission" do
      user = create(:user)
      login_as(user)
      board = create(:board)
      expect(board).not_to be_editable_by(user)
      delete :destroy, id: board.id
      expect(response).to redirect_to(board_url(board))
      expect(flash[:error]).to eq("You do not have permission to edit that continuity.")
    end

    it "succeeds" do
      board = create(:board)
      login_as(board.creator)
      delete :destroy, id: board.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:success]).to eq("Continuity deleted.")
    end
  end

  describe "POST mark" do
    it "requires login" do
      post :mark
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires board id" do
      login
      post :mark
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires valid board id" do
      login
      post :mark, board_id: -1
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires valid action" do
      login
      post :mark, board_id: create(:board).id
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Please choose a valid action.")
    end

    it "successfully marks board read" do
      board = create(:board)
      user = create(:user)
      login_as(user)
      now = Time.now
      expect(board.last_read(user)).to be_nil
      post :mark, board_id: board.id, commit: "Mark Read"
      expect(Board.find(board.id).last_read(user)).to be >= now # reload to reset cached @view
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("#{board.name} marked as read.")
    end

    it "successfully ignores board" do
      board = create(:board)
      user = create(:user)
      login_as(user)
      expect(board).not_to be_ignored_by(user)
      post :mark, board_id: board.id, commit: "Hide from Unread"
      expect(Board.find(board.id)).to be_ignored_by(user) # reload to reset cached @view
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("#{board.name} hidden from this page.")
    end
  end
end
