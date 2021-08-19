require 'rails_helper'

RSpec.describe "V1::PostsApi", type: :request do
  describe "POST /v1/posts - v1/posts#create - Create new post" do
    context "when client doesn't have token" do
      it "returns 401" do
        post v1_posts_path, params: {
          "content": 'Hello!',
        }
        expect(response).to have_http_status(401)
        expect(response.message).to include('Unauthorized')
      end
    end

    context "when client has token" do
      before do
        FactoryBot.create_list(:icon, 5)
      end

      let(:client_user) { FactoryBot.create(:user) }
      let(:headers)     { client_user.create_new_auth_token }

      it 'returns 200 and sets is_locked true when is_locked is true' do
        params = {
          content: 'Hello!',
          image: Rack::Test::UploadedFile.new(Rails.root.join("db/icons/Account-icon1.png"), "image/png"),
          is_locked: true,
        }
        expect do
          post v1_posts_path, params: params, headers: headers
        end.to change(Post.all, :count).by(1)
        expect(response).to have_http_status(200)
        expect(response.message).to include('OK')

        created_post = Post.find_by(user_id: get_current_user_by_response(response).id)

        expect(Icon.all.any? { |icon| created_post.icon_id == icon.id }).to be_truthy
        expect(created_post.is_locked).to eq(true)
        expect(created_post.content).to eq('Hello!')
      end

      it 'returns 200 and sets is_locked false when is_locked is nil' do
        params = {
          content: 'Hello!',
        }
        expect do
          post v1_posts_path, params: params, headers: headers
        end.to change(Post.all, :count).by(1)
        expect(response).to have_http_status(200)
        expect(response.message).to include('OK')

        created_post = Post.find_by(user_id: get_current_user_by_response(response).id)

        expect(created_post.is_locked).to eq(false)
      end

      it "returns 200 when content has 140 characters" do
        params = {
          content: 'a' * 140,
        }
        expect do
          post v1_posts_path, params: params, headers: headers
        end.to change(Post.all, :count).by(1)
        expect(response).to have_http_status(200)
        expect(response.message).to include('OK')
      end

      it "returns 400 when content has 141 characters" do
        params = {
          content: 'a' * 141,
        }
        post v1_posts_path, params: params, headers: headers
        expect(response).to have_http_status(400)
        expect(response.message).to include('Bad Request')
      end

      it "returns 400 when content is blank" do
        params = {
          content: '',
        }
        post v1_posts_path, params: params, headers: headers
        expect(response).to have_http_status(400)
        expect(response.message).to include('Bad Request')
      end

      it "returns 400 when content is nil" do
        params = {
          content: nil,
        }
        post v1_posts_path, params: params, headers: headers
        expect(response).to have_http_status(400)
        expect(response.message).to include('Bad Request')
      end

      it "returns 200 when image's extension isn't jpg or png or gif or jpeg" do
        params = {
          content: 'Hello!',
          image: Rack::Test::UploadedFile.new(Rails.root.join("db/icons/Account-icon1.svg"), "image/svg"),
          is_locked: true,
        }
        post v1_posts_path, params: params, headers: headers
        expect(response).to have_http_status(400)
        expect(response.message).to include('Bad Request')
      end
    end
  end

  describe "DELETE /v1/posts - v1/posts#destroy - Delete login user's post" do
    context "when client doesn't have token" do
      let(:client_user)       { FactoryBot.create(:user) }
      let!(:client_user_post) { FactoryBot.create(:post, user_id: client_user.id) }

      it "returns 401" do
        delete v1_post_path(client_user_post.id)
        expect(response).to have_http_status(401)
        expect(response.message).to include('Unauthorized')
      end
    end

    context "when client has token" do
      let(:client_user)           { FactoryBot.create(:user) }
      let(:headers)               { client_user.create_new_auth_token }
      let!(:client_user_post)     { FactoryBot.create(:post, user_id: client_user.id) }
      let(:not_client_user)       { FactoryBot.create(:user) }
      let!(:not_client_user_post) { FactoryBot.create(:post, user_id: not_client_user.id) }

      it "returns 200 and logically deletes post when try to delete login user's post" do
        expect do
          delete v1_post_path(client_user_post.id), headers: headers
        end.to change(Post.all, :count).by(-1)
        expect(response).to have_http_status(200)
        expect(response.message).to include('OK')
        expect(Post.with_deleted.where(id: client_user_post.id).count).to eq 1
      end

      it "returns 400 when try to delete not login user's post" do
        expect do
          delete v1_post_path(not_client_user_post.id), headers: headers
        end.to change(Post.all, :count).by(0)
        expect(response).to have_http_status(400)
        expect(response.message).to include('Bad Request')
      end
    end
  end

  describe "PUT /v1/posts/:id/change_lock - v1/posts#change_lock - Change is_locked of login user's post" do
    context "when client doesn't have token" do
      let(:user) { FactoryBot.create(:user) }
      let(:post) { FactoryBot.create(:post, user_id: user.id) }

      it "returns 401" do
        put v1_post_changeLock_path(post.id)
        expect(response).to have_http_status(401)
        expect(response.message).to include('Unauthorized')
      end
    end

    context "when client has token" do
      let(:user)              { FactoryBot.create(:user) }
      let(:post)              { FactoryBot.create(:post, user_id: user.id) }
      let(:headers)           { user.create_new_auth_token }
      let(:another_user)      { FactoryBot.create(:user) }
      let(:another_user_post) { FactoryBot.create(:post, user_id: another_user.id) }

      it "returns 200 and locks post when try to lock login user's unlocked post" do
        expect(Post.find(post.id).is_locked).to eq(false)

        put v1_post_changeLock_path(post.id), headers: headers
        expect(Post.find(post.id).is_locked).to eq(true)
        expect(response).to have_http_status(200)
        expect(response.message).to include('OK')
      end

      it "returns 200 and unlocks post when try to unlock login user's locked post" do
        Post.find(post.id).update(is_locked: true)
        expect(Post.find(post.id).is_locked).to eq(true)

        put v1_post_changeLock_path(post.id), headers: headers
        expect(Post.find(post.id).is_locked).to eq(false)
        expect(response).to have_http_status(200)
        expect(response.message).to include('OK')
      end

      it "returns 400 when try to lock not login user's unlocked post" do
        expect(Post.find(another_user_post.id).is_locked).to eq(false)

        put v1_post_changeLock_path(another_user_post.id), headers: headers
        expect(Post.find(another_user_post.id).is_locked).to eq(false)
        expect(response).to have_http_status(400)
        expect(response.message).to include('Bad Request')
      end

      it "returns 400 when try to unlock not login user's locked post" do
        Post.find(another_user_post.id).update(is_locked: true)
        expect(Post.find(another_user_post.id).is_locked).to eq(true)

        put v1_post_changeLock_path(another_user_post.id), headers: headers
        expect(Post.find(another_user_post.id).is_locked).to eq(true)
        expect(response).to have_http_status(400)
        expect(response.message).to include('Bad Request')
      end
    end
  end

  describe "POST /v1/posts/:id/reply - v1/posts#create_reply - Create reply" do
    context "when client doesn't have token" do
      let(:user)      { FactoryBot.create(:user) }
      let(:user_post) { FactoryBot.create(:post, user_id: user.id) }

      it "returns 401" do
        post v1_post_reply_path(user_post.id)
        expect(response).to have_http_status(401)
        expect(response.message).to include('Unauthorized')
      end
    end

    context "when client has token" do
      before do
        FactoryBot.create(:icon)
      end

      let(:client_user)   { FactoryBot.create(:user) }
      let(:headers)       { client_user.create_new_auth_token }
      let!(:replied_post) { FactoryBot.create(:post, user_id: client_user.id) }
      let(:params) do
        {
          content: 'Hello!',
          image: Rack::Test::UploadedFile.new(Rails.root.join("db/icons/Account-icon1.png"), "image/png"),
          is_locked: true,
        }
      end

      context "when try to reply to current_user's post with valid post in body" do
        it 'returns 200 and create post and tree_paths' do
          expect do
            post v1_post_reply_path(replied_post.id), params: params, headers: headers
          end.to change(Post, :count).by(1).and change(TreePath, :count).by(2)

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')

          reply_post = Post.order(created_at: :desc).limit(1)[0]
          expect(reply_post.user_id).to eq(client_user.id)
          expect(reply_post.content).to eq('Hello!')
          expect(reply_post.is_locked).to eq(true)
          expect(Icon.all.any? { |icon| reply_post.icon_id == icon.id }).to be_truthy

          expect(TreePath.where(ancestor: reply_post.id, descendant: reply_post.id, depth: 0)).to exist
          expect(TreePath.where(ancestor: replied_post.id, descendant: reply_post.id, depth: 1)).to exist
        end
      end

      context "when try to reply to current_user's post with invalid post in body" do
        it "returns 400 and doesn't create post and tree_path" do
          params = {
            content: '',
            image: Rack::Test::UploadedFile.new(Rails.root.join("db/icons/Account-icon1.png"), "image/png"),
            is_locked: true,
          }
          replied_post = FactoryBot.create(:post, user_id: client_user.id)
          expect do
            post v1_post_reply_path(replied_post.id), params: params, headers: headers
          end.to change(Post, :count).by(0).and change(TreePath, :count).by(0)
          expect(response).to have_http_status(400)
          expect(JSON.parse(response.body)["content"]).to include("can't be blank")
        end
      end

      context "when try to reply to current_user's post that it replied once before" do
        let(:replied_post) { FactoryBot.create(:post, user_id: client_user.id) }

        it 'returns 200 and create post and tree_path' do
          post v1_post_reply_path(replied_post.id), params: params, headers: headers
          first_reply_post = Post.order(created_at: :desc).limit(1)[0]

          expect do
            post v1_post_reply_path(first_reply_post.id), params: params, headers: headers
          end.to change(Post, :count).by(1).and change(TreePath, :count).by(3)

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')

          second_reply_post = Post.order(created_at: :desc).limit(1)[0]

          expect(TreePath.where(ancestor: second_reply_post.id, descendant: second_reply_post.id, depth: 0)).to exist
          expect(TreePath.where(ancestor: first_reply_post.id, descendant: second_reply_post.id, depth: 1)).to exist
          expect(TreePath.where(ancestor: replied_post.id, descendant: second_reply_post.id, depth: 2)).to exist
        end
      end

      context "when try to reply to current_user's post that it has two series of replies" do
        let(:replied_post) { FactoryBot.create(:post, user_id: client_user.id) }

        it 'returns 200 and create post and tree_path' do
          post v1_post_reply_path(replied_post.id), params: params, headers: headers
          first_reply_post = Post.order(created_at: :desc).limit(1)[0]
          post v1_post_reply_path(first_reply_post.id), params: params, headers: headers
          second_reply_post = Post.order(created_at: :desc).limit(1)[0]

          expect do
            post v1_post_reply_path(second_reply_post.id), params: params, headers: headers
          end.to change(Post, :count).by(1).and change(TreePath, :count).by(4)

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')

          third_reply_post = Post.order(created_at: :desc).limit(1)[0]

          expect(TreePath.where(ancestor: third_reply_post.id, descendant: third_reply_post.id, depth: 0)).to exist
          expect(TreePath.where(ancestor: second_reply_post.id, descendant: third_reply_post.id, depth: 1)).to exist
          expect(TreePath.where(ancestor: first_reply_post.id, descendant: third_reply_post.id, depth: 2)).to exist
          expect(TreePath.where(ancestor: replied_post.id, descendant: third_reply_post.id, depth: 3)).to exist
        end
      end

      context "when try to reply to mutual follower's post" do
        let(:mutual_follow_user)       { create_mutual_follow_user(client_user) }
        let!(:mutual_follow_user_post) { FactoryBot.create(:post, user_id: mutual_follow_user.id) }

        it 'returns 200 and create post and tree_path' do
          expect do
            post v1_post_reply_path(mutual_follow_user_post.id), params: params, headers: headers
          end.to change(Post, :count).by(1).and change(TreePath, :count).by(2)

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')

          reply_post = Post.order(created_at: :desc).limit(1)[0]

          expect(TreePath.where(ancestor: reply_post.id, descendant: reply_post.id, depth: 0)).to exist
          expect(TreePath.where(ancestor: mutual_follow_user_post.id, descendant: reply_post.id, depth: 1)).to exist
        end
      end

      context "when try to reply to not mutual follower's post" do
        let(:non_following_user)       { FactoryBot.create(:user) }
        let!(:non_following_user_post) { FactoryBot.create(:post, user_id: non_following_user.id) }

        it "returns 400 and doesn't create post and tree_path" do
          expect do
            post v1_post_reply_path(non_following_user_post.id), params: params, headers: headers
          end.to change(Post, :count).by(0).and change(TreePath, :count).by(0)

          expect(response).to have_http_status(400)
          expect(response.message).to include('Bad Request')
          expect(JSON.parse(response.body)['errors']['title']).to include('リプライ対象外の投稿です')
        end
      end

      context "when try to reply to non existent post" do
        let(:non_existent_post_id) { get_non_existent_post_id }

        it "returns 400 and doesn't create post and tree_path" do
          expect do
            post v1_post_reply_path(non_existent_post_id), params: params, headers: headers
          end.to change(Post, :count).by(0).and change(TreePath, :count).by(0)

          expect(response).to have_http_status(400)
          expect(response.message).to include('Bad Request')
          expect(JSON.parse(response.body)['errors']['title']).to include('投稿が存在しません')
        end
      end
    end
  end

  describe "GET /v1/posts/liked - v1/posts#index_liked_posts - Get liked posts" do
    context "when client doesn't have token" do
      it "returns 401" do
        get v1_liked_posts_path
        expect(response).to have_http_status(401)
        expect(response.message).to include('Unauthorized')
      end
    end

    context "when client has token" do
      before do
        FactoryBot.create(:icon)
      end

      let(:client_user)      { FactoryBot.create(:user) }
      let(:client_user_post) { FactoryBot.create(:post, user_id: client_user.id) }
      let(:headers)          { client_user.create_new_auth_token }
      let(:follower)         { create_mutual_follow_user(client_user) }
      let(:follower_post1)   { FactoryBot.create(:post, user_id: follower.id) }
      let(:follower_post2)   { FactoryBot.create(:post, user_id: follower.id) }

      context "when client has three posts" do
        it 'returns 200 and liked posts in descending order for time client liked' do
          post v1_post_likes_path(client_user_post.id), headers: headers
          post v1_post_likes_path(follower_post1.id), headers: headers
          post v1_post_likes_path(follower_post2.id), headers: headers

          get v1_liked_posts_path, headers: headers

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')
          response_body = JSON.parse(response.body)
          expect(response_body.length).to eq(3)
          expect(response_body[0].keys).to eq [
            "id",
            "content",
            "image",
            "icon_id",
            "is_locked",
            "deleted_at",
            "created_at",
            "updated_at",
          ]
          expect(response_body[1].keys).to eq [
            "id",
            "content",
            "image",
            "icon_id",
            "is_locked",
            "deleted_at",
            "created_at",
            "updated_at",
          ]
          expect(response_body[2].keys).to eq [
            "id",
            "content",
            "image",
            "icon_id",
            "is_locked",
            "deleted_at",
            "created_at",
            "updated_at",
          ]
          expect(response_body[0]).to have_id(follower_post2.id)
          expect(response_body[1]).to have_id(follower_post1.id)
          expect(response_body[2]).to have_id(client_user_post.id)
        end
      end

      context "when client has one posts" do
        it "returns 200 and liked post" do
          post v1_post_likes_path(client_user_post.id), headers: headers

          get v1_liked_posts_path, headers: headers

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')
          response_body = JSON.parse(response.body)
          expect(response_body[0].keys).to eq [
            "id",
            "content",
            "image",
            "icon_id",
            "is_locked",
            "deleted_at",
            "created_at",
            "updated_at",
          ]
          expect(response_body[0]).to have_id(client_user_post.id)
        end
      end

      context "when client doesn't have any posts" do
        it "returns 200 and no posts" do
          get v1_liked_posts_path, headers: headers

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')
          response_body = JSON.parse(response.body)
          expect(response_body[0]).to eq(nil)
        end
      end
    end
  end

  describe "GET /v1/posts/current_user_and_mutual_follower
  - v1/likes#index_current_user_and_mutual_follower_posts
  - Get current user and mutual follower posts" do
    context "when client doesn't have token" do
      it "returns 401" do
        get v1_current_user_and_mutual_follower_posts_path
        expect(response).to have_http_status(401)
        expect(response.message).to include('Unauthorized')
      end
    end

    context "when client has token" do
      before do
        FactoryBot.create(:icon)
      end

      let(:client_user)          { FactoryBot.create(:user) }
      let(:client_user_headers)  { client_user.create_new_auth_token }
      let(:follower1)            { create_mutual_follow_user(client_user) }
      let(:follower1_headers)    { follower1.create_new_auth_token }
      let(:follower2)            { create_mutual_follow_user(client_user) }
      let(:non_follower)         { FactoryBot.create(:user) }
      let(:non_follower_headers) { non_follower.create_new_auth_token }

      context "when client's, followers's and non-followers's posts are exist" do
        # ※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※
        # 各々のユーザの投稿について、リプライを持つものと持たないものを作成すること
        # ※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※※
        let!(:client_post_without_reply)       { FactoryBot.create(:post, user_id: client_user.id) }
        let!(:client_post_with_reply)          { FactoryBot.create(:post, user_id: client_user.id) }
        let!(:follower1_post_without_reply)    { FactoryBot.create(:post, user_id: follower1.id) }
        let!(:follower2_post_with_reply)       { FactoryBot.create(:post, user_id: follower2.id) }
        let!(:non_follower_post_without_reply) { FactoryBot.create(:post, user_id: non_follower.id) }
        let!(:non_follower_post_with_reply)    { FactoryBot.create(:post, user_id: non_follower.id) }

        let(:params) do
          {
            content: 'Hello!',
            image: Rack::Test::UploadedFile.new(Rails.root.join("db/icons/Account-icon1.png"), "image/png"),
            is_locked: true,
          }
        end

        before do
          post v1_post_reply_path(follower2_post_with_reply.id),    params: params, headers: client_user_headers
          post v1_post_reply_path(client_post_with_reply.id),       params: params, headers: client_user_headers
          post v1_post_reply_path(non_follower_post_with_reply.id), params: params, headers: non_follower_headers

          post v1_post_likes_path(client_post_with_reply.id), headers: client_user_headers
          post v1_post_likes_path(client_post_with_reply.id), headers: follower1_headers
        end

        it "return 200 and client's and followers's sorted posts" do
          get v1_current_user_and_mutual_follower_posts_path, headers: client_user_headers

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')

          response_body = JSON.parse(response.body, symbolize_names: true)

          expect(response_body.length).to eq(4)

          # ソートが正しく実装されているかテスト
          expect(response_body[0][:mutual_follower_post]).to have_id(follower2_post_with_reply.id)
          expect(response_body[1][:mutual_follower_post]).to have_id(follower1_post_without_reply.id)
          expect(response_body[2][:current_user_post]).to have_id(client_post_with_reply.id)
          expect(response_body[3][:current_user_post]).to have_id(client_post_without_reply.id)

          expect(response_body[0][:mutual_follower_post].length).to eq(10)
          expect(response_body[1][:mutual_follower_post].length).to eq(10)
          expect(response_body[2][:current_user_post].length).to eq(13)
          expect(response_body[3][:current_user_post].length).to eq(13)

          expect(response_body[2][:current_user_post]).to include(
            id: client_post_with_reply.id,
            content: client_post_with_reply.content,
            image: client_post_with_reply.image.url,
            is_locked: client_post_with_reply.is_locked,
            icon_url: client_user.image.url,
            likes: 2,
            replies: 1,
            is_liked_by_current_user: true,
            username: client_user.username,
            userid: client_user.userid,
          )
          expect(response_body[2][:current_user_post]).to include(
            :deleted_at,
            :created_at,
            :updated_at,
          )
          expect(response_body[1][:mutual_follower_post]).to include(
            id: follower1_post_without_reply.id,
            content: follower1_post_without_reply.content,
            image: follower1_post_without_reply.image.url,
            is_locked: follower1_post_without_reply.is_locked,
            icon_url: follower1_post_without_reply.icon.image.url,
            replies: 0,
            is_liked_by_current_user: false,
          )
          expect(response_body[1][:mutual_follower_post]).to include(
            :deleted_at,
            :created_at,
            :updated_at,
          )
        end
      end

      context "when client's post is exist" do
        let!(:client_post_without_reply) { FactoryBot.create(:post, user_id: client_user.id) }

        it "returns 200 and client's post" do
          get v1_current_user_and_mutual_follower_posts_path, headers: client_user_headers

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')

          response_body = JSON.parse(response.body, symbolize_names: true)

          expect(response_body.length).to eq(1)
          expect(response_body[0][:current_user_post].length).to eq(13)
          expect(response_body[0][:current_user_post]).to include(
            id: client_post_without_reply.id,
            content: client_post_without_reply.content,
            image: client_post_without_reply.image.url,
            is_locked: client_post_without_reply.is_locked,
            icon_url: client_user.image.url,
            likes: 0,
            replies: 0,
            is_liked_by_current_user: false,
            username: client_user.username,
            userid: client_user.userid,
          )
          expect(response_body[0][:current_user_post]).to include(
            :deleted_at,
            :created_at,
            :updated_at,
          )
        end
      end

      context "when follower's post is exist" do
        let!(:follower1_post_without_reply) { FactoryBot.create(:post, user_id: follower1.id) }

        it "returns 200 and follower's post" do
          get v1_current_user_and_mutual_follower_posts_path, headers: client_user_headers

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')

          response_body = JSON.parse(response.body, symbolize_names: true)

          expect(response_body.length).to eq(1)
          expect(response_body[0][:mutual_follower_post].length).to eq(10)
          expect(response_body[0][:mutual_follower_post]).to include(
            id: follower1_post_without_reply.id,
            content: follower1_post_without_reply.content,
            image: follower1_post_without_reply.image.url,
            is_locked: follower1_post_without_reply.is_locked,
            icon_url: follower1_post_without_reply.icon.image.url,
            replies: 0,
            is_liked_by_current_user: false,
          )
          expect(response_body[0][:mutual_follower_post]).to include(
            :deleted_at,
            :created_at,
            :updated_at,
          )
        end
      end

      context "when non-follower's post is exist" do
        let!(:non_follower_post_without_reply) { FactoryBot.create(:post, user_id: non_follower.id) }

        it 'returns 200 and no posts' do
          get v1_current_user_and_mutual_follower_posts_path, headers: client_user_headers

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')

          response_body = JSON.parse(response.body, symbolize_names: true)
          expect(response_body.length).to eq(0)
        end
      end

      context "when logically deleted client's post is exist" do
        let!(:client_post_without_reply) { FactoryBot.create(:post, user_id: client_user.id) }

        before do
          delete v1_post_path(client_post_without_reply.id), headers: client_user_headers
        end

        it 'returns 200 and no posts' do
          get v1_current_user_and_mutual_follower_posts_path, headers: client_user_headers

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')

          response_body = JSON.parse(response.body, symbolize_names: true)
          expect(response_body.length).to eq(0)
        end
      end

      context "when posts aren't exist" do
        it 'retruns 200 and no posts' do
          get v1_current_user_and_mutual_follower_posts_path, headers: client_user_headers

          expect(response).to have_http_status(200)
          expect(response.message).to include('OK')

          response_body = JSON.parse(response.body, symbolize_names: true)
          expect(response_body.length).to eq(0)
        end
      end
    end
  end
end
