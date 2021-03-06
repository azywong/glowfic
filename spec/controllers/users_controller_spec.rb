require "spec_helper"

RSpec.describe UsersController do
  describe "GET index" do
    it "succeeds when logged out" do
      get :index
      expect(response).to have_http_status(200)
    end

    it "succeeds when logged in" do
      login
      get :index
      expect(response).to have_http_status(200)
    end

    context "with moieties" do
      render_views

      it "displays the name" do
        user = create(:user, moiety: 'fed123', moiety_name: 'moietycolor')
        get :index
        expect(response.body).to include('moietycolor')
        expect(response.body).to include('fed123')
      end
    end
  end

  describe "GET new" do
    it "succeeds when logged out" do
      get :new
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Sign Up')
      expect(controller.gon.min).to eq(User::MIN_USERNAME_LEN)
      expect(controller.gon.max).to eq(User::MAX_USERNAME_LEN)
    end

    it "complains when logged in" do
      login
      post :create
      expect(response).to redirect_to(boards_path)
      expect(flash[:error]).to eq('You are already logged in.')
    end
  end

  describe "POST create" do
    it "complains when logged in" do
      login
      post :create
      expect(response).to redirect_to(boards_path)
      expect(flash[:error]).to eq('You are already logged in.')
    end

    it "requires beta secret" do
      post :create
      expect(response).to render_template(:new)
      expect(flash[:error]).to eq("This is in beta. Please come back later.")
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
      expect(controller.gon.min).to eq(User::MIN_USERNAME_LEN)
      expect(controller.gon.max).to eq(User::MAX_USERNAME_LEN)
    end

    it "requires valid fields" do
      post :create, secret: "ALLHAILTHECOIN"
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("There was a problem completing your sign up.")
      expect(assigns(:user)).not_to be_valid
      expect(assigns(:page_title)).to eq('Sign Up')
      expect(controller.gon.min).to eq(User::MIN_USERNAME_LEN)
      expect(controller.gon.max).to eq(User::MAX_USERNAME_LEN)
    end

    it "signs you up" do
      user = build(:user).attributes.merge(password: 'testpassword', password_confirmation: 'testpassword')
      expect {
        post :create, {secret: "ALLHAILTHECOIN"}.merge(user: user)
      }.to change{User.count}.by(1)
      expect(response).to redirect_to(root_url)
      expect(flash[:success]).to eq("User created! You have been logged in.")
      expect(assigns(:current_user)).not_to be_nil
      expect(assigns(:current_user).username).to eq(user['username'])
    end
  end

  describe "GET show" do
    it "requires valid user" do
      get :show, id: -1
      expect(response).to redirect_to(users_url)
      expect(flash[:error]).to eq("User could not be found.")
    end

    it "works when logged out" do
      user = create(:user)
      get :show, id: user.id
      expect(response.status).to eq(200)
    end

    it "works when logged in as someone else" do
      user = create(:user)
      login
      get :show, id: user.id
      expect(response.status).to eq(200)
    end

    it "works when logged in as yourself" do
      user = create(:user)
      login_as(user)
      get :show, id: user.id
      expect(response.status).to eq(200)
    end

    it "sets the correct variables" do
      user = create(:user)
      posts = 3.times.collect do create(:post, user: user) end
      create(:post)
      get :show, id: user.id
      expect(assigns(:page_title)).to eq(user.username)
      expect(assigns(:posts).to_a).to match_array(posts)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires own user" do
      user = create(:user)
      login
      get :edit, id: user.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq('You do not have permission to edit that user.')
    end

    it "succeeds" do
      user_id = login
      get :edit, id: user_id
      expect(response.status).to eq(200)
    end

    context "with views" do
      render_views

      it "displays options" do
        user_id = login
        get :edit, id: user_id
      end
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      user = create(:user)
      login_as(user)
      put :update, id: user.id, user: {moiety: 'A'}
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:error]).to eq('There was a problem with your changes.')
    end

    it "does not update another user" do
      user1 = create(:user)
      user2 = create(:user)
      login_as(user1)
      put :update, id: user2.id, user: {email: 'bademail@example.com'}
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq('You do not have permission to edit that user.')
      expect(user2.reload.email).not_to eq('bademail@example.com')
    end

    it "works with valid params" do
      user = create(:user)
      login_as(user)
      put :update, id: user.id, user: {email: 'testuser314@example.com', email_notifications: true, moiety_name: 'Testmoiety', moiety: 'AAAAAA'}
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:success]).to eq('Changes saved successfully.')

      user.reload
      expect(user.email).to eq('testuser314@example.com')
      expect(user.email_notifications).to be_true
      expect(user.moiety_name).to eq('Testmoiety')
      expect(user.moiety).to eq('AAAAAA')
    end

    it "updates username and still allows login" do
      pass = 'password123'
      user = create(:user, username: 'user123', password: pass)
      expect(user.authenticate(pass)).to be_true
      login_as(user)
      put :update, id: user.id, user: {username: 'user124'}
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:success]).to eq('Changes saved successfully.')

      user.reload
      expect(user.username).to eq('user124')
      expect(user.authenticate(pass)).to be_true
      expect(user.authenticate(pass + '1')).not_to be_true
    end
  end

  describe "POST username" do
    it "complains when logged in" do
      skip "TODO not yet implemented"
    end

    it "requires username" do
      post :username
      expect(response.json['error']).to eq("No username provided.")
    end

    it "finds user" do
      user = create(:user)
      post :username, username: user.username
      expect(response.json['username_free']).not_to be_true
    end

    it "finds free username" do
      user = create(:user)
      post :username, username: user.username + 'nope'
      expect(response.json['username_free']).to be_true
    end
  end

  describe "PUT password" do
    it "requires login" do
      put :password, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires own user" do
      user = create(:user)
      login
      put :password, id: user.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq('You do not have permission to edit that user.')
    end

    it "requires correct password" do
      pass = 'testpass'
      fakepass = 'wrongpass'
      newpass = 'newpass'
      user = create(:user, password: 'testpass')
      login_as(user)

      put :password, id: user.id, old_password: fakepass, user: {password: newpass, password_confirmation: newpass}

      expect(response).to render_template(:edit)
      expect(flash[:error]).to eq('Incorrect password entered.')
      user.reload
      expect(user.authenticate(pass)).to be_true
      expect(user.authenticate(fakepass)).not_to be_true
      expect(user.authenticate(newpass)).not_to be_true
    end

    it "requires valid password" do
      pass = 'testpass'
      newpass = 'bad'
      user = create(:user, password: pass)
      login_as(user)

      put :password, id: user.id, old_password: pass, user: {password: newpass, password_confirmation: newpass}

      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq('There was a problem with your changes.')
      expect(user.authenticate(pass)).to be_true
      expect(user.authenticate(newpass)).not_to be_true
    end

    it "requires valid confirmation" do
      pass = 'testpass'
      newpass = 'newpassword'
      user = create(:user, password: pass)
      login_as(user)

      put :password, id: user.id, old_password: pass, user: {password: newpass, password_confirmation: 'wrongconfirmation'}

      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq('There was a problem with your changes.')
      user.reload
      expect(user.authenticate(pass)).to be_true
      expect(user.authenticate(newpass)).not_to be_true
    end

    it "succeeds" do
      pass = 'testpass'
      newpass = 'newpassword'
      user = create(:user, password: pass)
      login_as(user)

      put :password, id: user.id, old_password: pass, user: {password: newpass, password_confirmation: newpass}

      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:success]).to eq('Changes saved successfully.')
      user.reload
      expect(user.authenticate(pass)).not_to be_true
      expect(user.authenticate(newpass)).to be_true
    end

    it "has more tests" do
      skip
    end
  end
end
