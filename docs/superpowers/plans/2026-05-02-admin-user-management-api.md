# Admin User Management API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `/api/v1/admin/users` HTTP API on Forem that lets MLH Core programmatically read users, update profiles/emails/status, merge accounts, manage admin notes, and link/unlink third-party identities — primarily so Core can record "this Forem user is MLH ID X."

**Architecture:** Three new controllers in the `Api::V1::Admin` namespace (users extended, plus new `user_notes` and `user_identities`), each backed by a thin shared concern, with JBuilder views for response shapes. A new `Api::V1::Admin::BaseController` adds typed error handling and an audit-logging helper on top of the existing `Api::V1::ApiController`. All endpoints reuse existing service objects (`Moderator::MergeUser`, `Moderator::ManageActivityAndRoles`, `Users::Update`) and the existing `Note` and `Identity` models. Auth: existing `authenticate!` + `authorize_super_admin`. Identity linking is **strict-fail-closed** on conflicts; the unique DB indexes on `(provider, uid)` and `(provider, user_id)` already exist.

**Tech Stack:** Ruby on Rails, RSpec, FactoryBot, JBuilder. Existing Forem stack — no new dependencies.

**Reference spec:** `docs/superpowers/specs/2026-05-02-admin-user-management-api-design.md`

---

## File map

| File | Status | Responsibility |
|---|---|---|
| `app/errors/api/admin/api_error.rb` | create | Typed error class with `error_code` and `status` |
| `app/controllers/api/v1/admin/base_controller.rb` | create | Shared base: auth, error rendering, audit helper |
| `app/controllers/concerns/api/admin/users_controller.rb` | modify | Add `index`, `show`, `update`, `update_email`, `update_status`, `merge` actions |
| `app/controllers/api/v1/admin/users_controller.rb` | modify | Wire new actions, swap to inherit from `BaseController` |
| `app/controllers/concerns/api/admin/user_notes_controller.rb` | create | `index`, `create` |
| `app/controllers/api/v1/admin/user_notes_controller.rb` | create | Thin V1 wrapper |
| `app/controllers/concerns/api/admin/user_identities_controller.rb` | create | `index`, `create`, `destroy` with strict semantics |
| `app/controllers/api/v1/admin/user_identities_controller.rb` | create | Thin V1 wrapper |
| `app/views/api/v1/admin/users/{index,show,update,merge}.json.jbuilder` | create | User response shapes |
| `app/views/api/v1/admin/user_notes/{index,create}.json.jbuilder` | create | Note response shapes |
| `app/views/api/v1/admin/user_identities/{index,create}.json.jbuilder` | create | Identity response shapes |
| `app/views/api/v1/admin/users/_user.json.jbuilder` | create | Shared user partial |
| `app/views/api/v1/admin/user_identities/_identity.json.jbuilder` | create | Shared identity partial |
| `app/views/api/v1/admin/user_notes/_note.json.jbuilder` | create | Shared note partial |
| `config/routes/api.rb` | modify | Extend `namespace :admin` with new routes |
| `config/locales/en.yml` | modify | Error / message strings |
| `config/locales/fr.yml` | modify | Error / message strings (translated) |
| `config/locales/pt.yml` | modify | Error / message strings (translated) |
| `spec/requests/api/v1/admin/users_spec.rb` | create | Request specs for users controller |
| `spec/requests/api/v1/admin/user_notes_spec.rb` | create | Request specs for notes controller |
| `spec/requests/api/v1/admin/user_identities_spec.rb` | create | Request specs for identities controller |
| `spec/requests/authenticator_api_link_round_trip_spec.rb` | create | OAuth callback round-trip verification |
| `spec/support/api_admin_helpers.rb` | create | Shared helper for super_admin api-key headers |

---

## Conventions for every task

- **Test command shortcut**: `bundle exec rspec <path>` or `bundle exec rspec <path>:<line>`
- **Auth in specs**: every spec uses the helper from `spec/support/api_admin_helpers.rb` to build an API key and expected headers.
- **JSON parsing in specs**: `response.parsed_body` (Rails 7+).
- **Audit log subscription in specs**: `:admin_api` is NOT subscribed in test env (see `config/initializers/audit_events.rb`). **Every spec file that asserts on `AuditLog` must include** at the top of the outermost `describe`:

  ```ruby
  before { Audit::Subscribe.listen :admin_api }
  after  { Audit::Subscribe.forget :admin_api }
  ```

  This matches the pattern in `spec/requests/api/v1/user_roles_spec.rb`. Without it, `AuditLog.count` won't change and assertions will silently fail.
- **Audit log assertion pattern**:

  ```ruby
  expect { ... }.to change(AuditLog, :count).by(1)
  audit = AuditLog.last
  expect(audit.category).to eq("admin_api.audit.log")
  expect(audit.slug).to eq("link_identity")
  expect(audit.data).to include("target_user_id" => target.id, "provider" => "mlh")
  ```

- **Commits**: each task ends with a single commit. Conventional commit prefix `feat:`, `test:`, `refactor:`, etc. — match existing Forem style. Stage only files touched by the task; never `git add -A`.

---

## Task 1: Typed error class for the admin API

**Files:**
- Create: `app/errors/api/admin/api_error.rb`
- Test: `spec/errors/api/admin/api_error_spec.rb`

- [ ] **Step 1: Write the failing test**

Create `spec/errors/api/admin/api_error_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Api::Admin::ApiError do
  it "exposes error_code, status, and message" do
    err = described_class.new(:user_not_found, "User 42 not found", status: 404)

    expect(err.error_code).to eq(:user_not_found)
    expect(err.status).to eq(404)
    expect(err.message).to eq("User 42 not found")
  end

  it "defaults status to 400 when omitted" do
    err = described_class.new(:bad_request, "Bad request")

    expect(err.status).to eq(400)
  end

  it "is a StandardError subclass so rescue_from picks it up" do
    expect(described_class.ancestors).to include(StandardError)
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/errors/api/admin/api_error_spec.rb`
Expected: FAIL with "uninitialized constant Api::Admin::ApiError" or similar.

- [ ] **Step 3: Implement**

Create `app/errors/api/admin/api_error.rb`:

```ruby
module Api
  module Admin
    class ApiError < StandardError
      attr_reader :error_code, :status

      def initialize(error_code, message, status: 400)
        @error_code = error_code
        @status = status
        super(message)
      end
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/errors/api/admin/api_error_spec.rb`
Expected: 3 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/errors/api/admin/api_error.rb spec/errors/api/admin/api_error_spec.rb
git commit -m "Add Api::Admin::ApiError for typed admin API errors"
```

---

## Task 2: API admin spec helper

**Files:**
- Create: `spec/support/api_admin_helpers.rb`
- Modify: `spec/rails_helper.rb` (verify `spec/support/**/*.rb` is auto-loaded; if not, add a require)

- [ ] **Step 1: Verify auto-loading of `spec/support`**

Run: `grep -n "spec/support" spec/rails_helper.rb`
Expected: a line like `Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }` or `Rails.root.glob("spec/support/...")`.

If absent, add this line near the top of `spec/rails_helper.rb` (after `require 'rspec/rails'`):

```ruby
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
```

- [ ] **Step 2: Create the helper**

Create `spec/support/api_admin_helpers.rb`:

```ruby
module ApiAdminHelpers
  def admin_api_headers(user: nil)
    user ||= create(:user, :super_admin)
    secret = create(:api_secret, user: user).secret
    { "api-key" => secret, "Accept" => "application/vnd.forem.api-v1+json" }
  end

  def non_admin_api_headers
    user = create(:user)
    secret = create(:api_secret, user: user).secret
    { "api-key" => secret, "Accept" => "application/vnd.forem.api-v1+json" }
  end
end

RSpec.configure do |config|
  config.include ApiAdminHelpers, type: :request
end
```

- [ ] **Step 3: Smoke-test the helper**

Run: `bundle exec rspec spec/support/api_admin_helpers.rb 2>&1 | head -10`
Expected: no error (file is required at boot; it's not a spec file itself, but should not raise).

Run a quick eval: `bundle exec rails runner 'puts ApiAdminHelpers.instance_methods'`
Expected: prints `[:admin_api_headers, :non_admin_api_headers]`.

- [ ] **Step 4: Commit**

```bash
git add spec/support/api_admin_helpers.rb spec/rails_helper.rb
git commit -m "Add ApiAdminHelpers for super_admin api-key auth in request specs"
```

---

## Task 3: BaseController — auth, error rendering, audit helper

**Files:**
- Create: `app/controllers/api/v1/admin/base_controller.rb`
- Test: `spec/requests/api/v1/admin/base_controller_spec.rb`

- [ ] **Step 1: Write the failing test**

Create `spec/requests/api/v1/admin/base_controller_spec.rb`:

```ruby
require "rails_helper"

# Validate BaseController behavior via a real subclass mounted at a temporary route.
RSpec.describe Api::V1::Admin::BaseController, type: :request do
  before { Audit::Subscribe.listen :admin_api }
  after  { Audit::Subscribe.forget :admin_api }

  controller_class = Class.new(described_class) do
    def index
      raise Api::Admin::ApiError.new(:test_conflict, "test", status: 409) if params[:raise] == "conflict"
      raise ActiveRecord::RecordNotFound, "User Couldn't be found" if params[:raise] == "ar_not_found"

      audit!(slug: "test_action", data: { "target_user_id" => 1 })
      render json: { ok: true }
    end
  end

  before do
    stub_const("Api::V1::Admin::TestProbeController", controller_class)
    Rails.application.routes.draw do
      namespace :api do
        namespace :v1 do
          namespace :admin do
            get "test_probe", to: "test_probe#index"
          end
        end
      end
    end
  end

  after { Rails.application.reload_routes! }

  context "without an api key" do
    it "returns 401" do
      get "/api/v1/admin/test_probe"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with a non-super-admin api key" do
    it "returns 401" do
      get "/api/v1/admin/test_probe", headers: non_admin_api_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with a super_admin api key" do
    it "renders successfully and emits an audit log" do
      expect {
        get "/api/v1/admin/test_probe", headers: admin_api_headers
      }.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("ok" => true)
      audit = AuditLog.last
      expect(audit.category).to eq("admin_api.audit.log")
      expect(audit.slug).to eq("test_action")
      expect(audit.data).to include("target_user_id" => 1)
    end

    it "renders Api::Admin::ApiError as the standard envelope" do
      get "/api/v1/admin/test_probe", params: { raise: "conflict" }, headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq(
        "error" => "test", "error_code" => "test_conflict", "status" => 409,
      )
    end

    it "maps RecordNotFound to a 404 with error_code" do
      get "/api/v1/admin/test_probe", params: { raise: "ar_not_found" }, headers: admin_api_headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to include("error_code" => "not_found", "status" => 404)
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/requests/api/v1/admin/base_controller_spec.rb`
Expected: FAIL with "uninitialized constant Api::V1::Admin::BaseController".

- [ ] **Step 3: Implement**

Create `app/controllers/api/v1/admin/base_controller.rb`:

```ruby
module Api
  module V1
    module Admin
      class BaseController < Api::V1::ApiController
        before_action :authenticate!
        before_action :authorize_super_admin
        after_action :flush_audit, if: -> { response.successful? && @audit_payload }

        rescue_from Api::Admin::ApiError do |exc|
          render json: error_envelope(exc.message, exc.error_code, exc.status), status: exc.status
        end

        rescue_from ActiveRecord::RecordNotFound do |exc|
          render json: error_envelope(exc.message, :not_found, 404), status: :not_found
        end

        rescue_from ActiveRecord::RecordInvalid do |exc|
          render json: error_envelope(exc.message, :validation_failed, 422)
            .merge(errors: exc.record.errors.to_hash(true)), status: :unprocessable_entity
        end

        private

        # Used by action methods to declare an audit log entry.
        # The audit row is only persisted if the response is successful.
        def audit!(slug:, data:)
          @audit_payload = { slug: slug.to_s, data: data.stringify_keys }
        end

        def flush_audit
          slug = @audit_payload.fetch(:slug)
          data = @audit_payload.fetch(:data).merge("action" => slug)
          Audit::Logger.log(:admin_api, current_user, data)
        end

        def current_user
          @user
        end

        def error_envelope(message, error_code, status)
          { error: message, error_code: error_code.to_s, status: status }
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/requests/api/v1/admin/base_controller_spec.rb`
Expected: 5 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/api/v1/admin/base_controller.rb spec/requests/api/v1/admin/base_controller_spec.rb
git commit -m "Add Api::V1::Admin::BaseController with auth, error envelope, audit helper"
```

---

## Task 4: Routes — extend `namespace :admin`

**Files:**
- Modify: `config/routes/api.rb` (lines 4–6)

Forem's V1 routes are gated by `ApiConstraints` (require `Accept: application/vnd.forem.api-v1+json`), so a standard `to route_to` routing spec doesn't reach them. Forem has no existing API routing specs for that reason. We add routes here without a dedicated routing spec — request specs in Tasks 5–14 exercise every route end-to-end and will fail if any path is wrong.

- [ ] **Step 1: Inspect current routes**

Run: `bundle exec rails routes | grep admin/users`
Expected: only `POST /api/v1/admin/users` (the invite endpoint).

- [ ] **Step 2: Implement**

Edit `config/routes/api.rb`. Replace lines 4–6:

```ruby
namespace :admin do
  resources :users, only: [:create]
end
```

with:

```ruby
namespace :admin do
  resources :users, only: %i[index show create update] do
    member do
      put :email, action: :update_email
      put :status, action: :update_status
      post :merge
    end

    resources :notes, only: %i[index create], controller: "user_notes"
    resources :identities, only: %i[index create destroy], controller: "user_identities"
  end
end
```

- [ ] **Step 3: Verify routes resolved**

Run: `bundle exec rails routes | grep "admin/users"`
Expected output (in any order):

```
api_admin_user_email PUT  /api/v1/admin/users/:id/email     api/v1/admin/users#update_email
api_admin_user_status PUT /api/v1/admin/users/:id/status    api/v1/admin/users#update_status
api_admin_user_merge POST /api/v1/admin/users/:id/merge     api/v1/admin/users#merge
api_admin_user_notes GET  /api/v1/admin/users/:user_id/notes api/v1/admin/user_notes#index
... (more)
```

Plus the existing `POST /api/v1/admin/users` (invite).

- [ ] **Step 4: Commit**

```bash
git add config/routes/api.rb
git commit -m "Add admin user/note/identity API routes under /api/v1/admin"
```

---

## Task 5: Users `index` — list & search with filters

**Files:**
- Modify: `app/controllers/concerns/api/admin/users_controller.rb`
- Modify: `app/controllers/api/v1/admin/users_controller.rb`
- Create: `app/views/api/v1/admin/users/index.json.jbuilder`
- Create: `app/views/api/v1/admin/users/_user.json.jbuilder`
- Test: `spec/requests/api/v1/admin/users_spec.rb`

- [ ] **Step 1: Write the failing test**

Create `spec/requests/api/v1/admin/users_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Api::V1::Admin::Users", type: :request do
  before { Audit::Subscribe.listen :admin_api }
  after  { Audit::Subscribe.forget :admin_api }

  describe "GET /api/v1/admin/users" do
    let!(:older) { create(:user, email: "alpha@example.com", username: "alpha_user", created_at: 2.days.ago) }
    let!(:newer) { create(:user, email: "beta@example.com",  username: "beta_user",  created_at: 1.day.ago) }

    it "rejects requests without an api key" do
      get "/api/v1/admin/users"
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects non-super-admin callers" do
      get "/api/v1/admin/users", headers: non_admin_api_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns users ordered by created_at DESC" do
      get "/api/v1/admin/users", headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["users"].map { |u| u["id"] }
      expect(ids.first(2)).to eq([newer.id, older.id])
    end

    it "filters by exact email" do
      get "/api/v1/admin/users", params: { email: "alpha@example.com" }, headers: admin_api_headers

      expect(response.parsed_body["users"].map { |u| u["id"] }).to eq([older.id])
    end

    it "filters by exact username" do
      get "/api/v1/admin/users", params: { username: "beta_user" }, headers: admin_api_headers

      expect(response.parsed_body["users"].map { |u| u["id"] }).to eq([newer.id])
    end

    it "filters by identity_provider + identity_uid" do
      create(:identity, user: older, provider: "mlh", uid: "core-12345")

      get "/api/v1/admin/users",
          params: { identity_provider: "mlh", identity_uid: "core-12345" },
          headers: admin_api_headers

      expect(response.parsed_body["users"].map { |u| u["id"] }).to eq([older.id])
    end

    it "paginates with page and per_page" do
      get "/api/v1/admin/users", params: { page: 1, per_page: 1 }, headers: admin_api_headers

      body = response.parsed_body
      expect(body["users"].size).to eq(1)
      expect(body["page"]).to eq(1)
      expect(body["per_page"]).to eq(1)
      expect(body["total"]).to be >= 2
    end

    it "clamps per_page above 100 to 100" do
      get "/api/v1/admin/users", params: { per_page: 999 }, headers: admin_api_headers

      expect(response.parsed_body["per_page"]).to eq(100)
    end

    it "does not log an audit entry for reads" do
      expect {
        get "/api/v1/admin/users", headers: admin_api_headers
      }.not_to change(AuditLog, :count)
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb`
Expected: most FAIL with routing/missing-action errors; auth-related ones may pass once Task 4 routes exist.

- [ ] **Step 3: Implement the concern**

Edit `app/controllers/concerns/api/admin/users_controller.rb`. The file currently defines only `create`. Replace its full contents with:

```ruby
module Api
  module Admin
    module UsersController
      extend ActiveSupport::Concern

      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      def index
        users = filtered_users
        page = positive_integer(params[:page], default: 1)
        per_page = [positive_integer(params[:per_page], default: DEFAULT_PER_PAGE), MAX_PER_PAGE].min

        total = users.count
        @users = users.order(created_at: :desc).offset((page - 1) * per_page).limit(per_page)
        @page = page
        @per_page = per_page
        @total = total
      end

      def create
        # NOTE: We can add an inviting user here, e.g. User.invite!(current_user, user_params).
        options = {
          custom_invite_subject: params[:custom_invite_subject],
          custom_invite_message: params[:custom_invite_message],
          custom_invite_footnote: params[:custom_invite_footnote]
        }

        User.invite!(invite_params.merge(registered: false), nil, options)

        head :ok
      end

      private

      def filtered_users
        scope = User.all
        scope = scope.where(email: params[:email]) if params[:email].present?
        scope = scope.where(username: params[:username]) if params[:username].present?
        if params[:identity_provider].present? && params[:identity_uid].present?
          scope = scope.joins(:identities)
                       .where(identities: {
                                provider: params[:identity_provider],
                                uid: params[:identity_uid],
                              })
        end
        scope
      end

      def positive_integer(value, default:)
        n = value.to_i
        n.positive? ? n : default
      end

      # NOTE: username is required for the validations on User to succeed.
      def invite_params
        {
          email: params.require(:email),
          name: params[:name],
          username: params[:email]
        }.compact_blank
      end
    end
  end
end
```

- [ ] **Step 4: Update the V1 wrapper to use BaseController**

Replace `app/controllers/api/v1/admin/users_controller.rb` with:

```ruby
module Api
  module V1
    module Admin
      class UsersController < BaseController
        include Api::Admin::UsersController
      end
    end
  end
end
```

(The existing `before_action :authenticate!` and `before_action :authorize_super_admin` are already declared on `BaseController`.)

- [ ] **Step 5: Create the JBuilder views**

Create `app/views/api/v1/admin/users/_user.json.jbuilder`:

```ruby
json.id user.id
json.username user.username
json.name user.name
json.email user.email
json.registered_at user.registered_at
json.status user_moderation_status(user)
json.profile do
  profile = user.profile
  json.summary profile&.summary
  json.location profile&.location
  json.website_url profile&.website_url
end
json.identities user.identities do |identity|
  json.partial!("api/v1/admin/user_identities/identity", identity: identity)
end
json.counts do
  json.articles user.articles_count
  json.comments user.comments_count
  json.reactions user.reactions_count
end
```

Create `app/views/api/v1/admin/users/index.json.jbuilder`:

```ruby
json.users(@users) do |user|
  json.partial!("api/v1/admin/users/user", user: user)
end
json.page @page
json.per_page @per_page
json.total @total
```

Also create the identity partial referenced by `_user.json.jbuilder` above. (Tasks 12–14 add controller logic, but the partial itself is complete here — `id`, `provider`, `uid`, `created_at` are the only fields the API exposes.)

Create `app/views/api/v1/admin/user_identities/_identity.json.jbuilder`:

```ruby
json.id identity.id
json.provider identity.provider
json.uid identity.uid
json.created_at identity.created_at
```

- [ ] **Step 6: Add `user_moderation_status` helper**

The `_user.json.jbuilder` partial calls `user_moderation_status(user)`. Add it to `app/helpers/admin_api_users_helper.rb`:

Create `app/helpers/admin_api_users_helper.rb`:

```ruby
module AdminApiUsersHelper
  STATUS_PRIORITY = %w[suspended spam warned comment_suspended limited trusted].freeze

  def user_moderation_status(user)
    role = STATUS_PRIORITY.find { |r| user.has_role?(r.to_sym) }
    role || "good_standing"
  end
end
```

This module is auto-included in views by Rails. (If Forem requires explicit inclusion of helpers in API JBuilder views, verify by running the spec; if it complains "undefined method `user_moderation_status`", add `include AdminApiUsersHelper` to `Api::V1::ApiController`.)

- [ ] **Step 7: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb`
Expected: 8 examples, 0 failures.

- [ ] **Step 8: Commit**

```bash
git add app/controllers/concerns/api/admin/users_controller.rb \
        app/controllers/api/v1/admin/users_controller.rb \
        app/views/api/v1/admin/users/index.json.jbuilder \
        app/views/api/v1/admin/users/_user.json.jbuilder \
        app/views/api/v1/admin/user_identities/_identity.json.jbuilder \
        app/helpers/admin_api_users_helper.rb \
        spec/requests/api/v1/admin/users_spec.rb
git commit -m "Add GET /api/v1/admin/users index with filters and pagination"
```

---

## Task 6: Users `show` — single user lookup

**Files:**
- Modify: `app/controllers/concerns/api/admin/users_controller.rb`
- Create: `app/views/api/v1/admin/users/show.json.jbuilder`
- Modify: `spec/requests/api/v1/admin/users_spec.rb` (append)

- [ ] **Step 1: Append failing tests**

Append to `spec/requests/api/v1/admin/users_spec.rb`:

```ruby
  describe "GET /api/v1/admin/users/:id" do
    let!(:user) { create(:user) }

    it "returns the user payload" do
      create(:identity, user: user, provider: "mlh", uid: "core-99")

      get "/api/v1/admin/users/#{user.id}", headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(user.id)
      expect(body["username"]).to eq(user.username)
      expect(body["identities"].map { |i| i["uid"] }).to include("core-99")
    end

    it "returns 404 with error_code for missing user" do
      get "/api/v1/admin/users/999999", headers: admin_api_headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error_code"]).to eq("not_found")
    end

    it "does not log an audit entry" do
      expect {
        get "/api/v1/admin/users/#{user.id}", headers: admin_api_headers
      }.not_to change(AuditLog, :count)
    end
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb`
Expected: new examples FAIL ("No route matches" or action not defined).

- [ ] **Step 3: Add the action**

In `app/controllers/concerns/api/admin/users_controller.rb`, add a `show` method right after `index`:

```ruby
def show
  @user_record = User.find(params[:id])
end
```

Note: `@user` is reserved by `Api::V1::ApiController` for the *caller*. Use `@user_record` (or any other name) for the target user.

- [ ] **Step 4: Create show.json.jbuilder**

Create `app/views/api/v1/admin/users/show.json.jbuilder`:

```ruby
json.partial!("api/v1/admin/users/user", user: @user_record)
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb`
Expected: 11 examples, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/concerns/api/admin/users_controller.rb \
        app/views/api/v1/admin/users/show.json.jbuilder \
        spec/requests/api/v1/admin/users_spec.rb
git commit -m "Add GET /api/v1/admin/users/:id"
```

---

## Task 7: Users `update` — profile fields via Users::Update

**Files:**
- Modify: `app/controllers/concerns/api/admin/users_controller.rb`
- Create: `app/views/api/v1/admin/users/update.json.jbuilder`
- Modify: `spec/requests/api/v1/admin/users_spec.rb` (append)

- [ ] **Step 1: Append failing tests**

Append to `spec/requests/api/v1/admin/users_spec.rb`:

```ruby
  describe "PATCH /api/v1/admin/users/:id" do
    let!(:user) { create(:user, name: "Old Name", username: "old_username") }

    it "updates name and username" do
      patch "/api/v1/admin/users/#{user.id}",
            params: { name: "New Name", username: "new_username" },
            headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.name).to eq("New Name")
      expect(user.username).to eq("new_username")
    end

    it "updates profile fields summary, location, website_url" do
      patch "/api/v1/admin/users/#{user.id}",
            params: { summary: "New summary", location: "Brooklyn", website_url: "https://example.com" },
            headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      profile = user.reload.profile
      expect(profile.summary).to eq("New summary")
      expect(profile.location).to eq("Brooklyn")
      expect(profile.website_url).to eq("https://example.com")
    end

    it "ignores unsupported fields silently" do
      patch "/api/v1/admin/users/#{user.id}",
            params: { reputation_modifier: 99 },
            headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.reputation_modifier).not_to eq(99)
    end

    it "returns 422 with errors hash on validation failure" do
      taken_user = create(:user, username: "taken_username")
      patch "/api/v1/admin/users/#{user.id}",
            params: { username: taken_user.username },
            headers: admin_api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.parsed_body
      expect(body["error_code"]).to eq("validation_failed")
      expect(body["errors"]).to have_key("username")
    end

    it "logs an audit entry with changed fields" do
      expect {
        patch "/api/v1/admin/users/#{user.id}",
              params: { name: "Audit Name" },
              headers: admin_api_headers
      }.to change(AuditLog, :count).by(1)

      audit = AuditLog.last
      expect(audit.slug).to eq("update_user")
      expect(audit.data["target_user_id"]).to eq(user.id)
      expect(audit.data["changed"]).to include("name")
    end
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb -e "PATCH"`
Expected: failures (action missing).

- [ ] **Step 3: Add the action**

In `app/controllers/concerns/api/admin/users_controller.rb`, add:

```ruby
USER_UPDATE_FIELDS = %i[name username].freeze
PROFILE_UPDATE_FIELDS = %i[summary location website_url].freeze

def update
  @user_record = User.find(params[:id])
  before_user = @user_record.slice(*USER_UPDATE_FIELDS)
  before_profile = (@user_record.profile || @user_record.build_profile).slice(*PROFILE_UPDATE_FIELDS)

  user_attrs    = params.permit(*USER_UPDATE_FIELDS).to_h.symbolize_keys
  profile_attrs = params.permit(*PROFILE_UPDATE_FIELDS).to_h.symbolize_keys

  result = Users::Update.call(@user_record, user: user_attrs, profile: profile_attrs)
  unless result.success?
    raise ActiveRecord::RecordInvalid, @user_record_with_errors_for(result, @user_record)
  end

  after_user = @user_record.reload.slice(*USER_UPDATE_FIELDS)
  after_profile = (@user_record.profile || Profile.new).slice(*PROFILE_UPDATE_FIELDS)
  changed = diff_changed(before_user.merge(before_profile), after_user.merge(after_profile))

  audit!(slug: "update_user", data: { "target_user_id" => @user_record.id, "changed" => changed })
end

private

def @user_record_with_errors_for(_result, user_record)
  # Users::Update collects errors on the underlying user/profile records;
  # surface them by raising RecordInvalid on the user (BaseController catches it).
  user_record.tap do |u|
    # If validations failed on Profile, copy onto user.errors for the response.
    profile_errors = u.profile&.errors&.messages || {}
    profile_errors.each { |attr, msgs| msgs.each { |m| u.errors.add(attr, m) } }
  end
end

def diff_changed(before, after)
  before.each_with_object({}) do |(key, before_val), memo|
    after_val = after[key]
    memo[key.to_s] = [before_val, after_val] if before_val != after_val
  end
end
```

Reorder so `private` only appears once at the bottom of the module. The final structure of the file should be:

```
module Api::Admin::UsersController
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = ...
  MAX_PER_PAGE = ...
  USER_UPDATE_FIELDS = ...
  PROFILE_UPDATE_FIELDS = ...

  def index ...
  def show ...
  def update ...
  def create ...

  private

  def filtered_users ...
  def positive_integer ...
  def invite_params ...
  def diff_changed ...
  def @user_record_with_errors_for ...
end
```

(The Ruby-flavored "@" prefix on the private helper name above is invalid syntax — use a normal name. Replace with `apply_profile_errors!`. The corrected `update` action body:)

```ruby
def update
  @user_record = User.find(params[:id])
  before_user = @user_record.slice(*USER_UPDATE_FIELDS)
  before_profile = (@user_record.profile || @user_record.build_profile).slice(*PROFILE_UPDATE_FIELDS)

  user_attrs    = params.permit(*USER_UPDATE_FIELDS).to_h.symbolize_keys
  profile_attrs = params.permit(*PROFILE_UPDATE_FIELDS).to_h.symbolize_keys

  result = Users::Update.call(@user_record, user: user_attrs, profile: profile_attrs)
  unless result.success?
    apply_profile_errors!(@user_record)
    raise ActiveRecord::RecordInvalid, @user_record
  end

  after_user = @user_record.reload.slice(*USER_UPDATE_FIELDS)
  after_profile = (@user_record.profile || Profile.new).slice(*PROFILE_UPDATE_FIELDS)
  changed = diff_changed(before_user.merge(before_profile), after_user.merge(after_profile))

  audit!(slug: "update_user", data: { "target_user_id" => @user_record.id, "changed" => changed })
end
```

And the corrected helper:

```ruby
def apply_profile_errors!(user_record)
  profile_errors = user_record.profile&.errors&.messages || {}
  profile_errors.each { |attr, msgs| msgs.each { |m| user_record.errors.add(attr, m) } }
end
```

- [ ] **Step 4: Create update.json.jbuilder**

Create `app/views/api/v1/admin/users/update.json.jbuilder`:

```ruby
json.partial!("api/v1/admin/users/user", user: @user_record)
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb -e "PATCH"`
Expected: 5 examples, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/concerns/api/admin/users_controller.rb \
        app/views/api/v1/admin/users/update.json.jbuilder \
        spec/requests/api/v1/admin/users_spec.rb
git commit -m "Add PATCH /api/v1/admin/users/:id for profile updates"
```

---

## Task 8: Users `update_email` — email change, skip Devise confirmation

**Files:**
- Modify: `app/controllers/concerns/api/admin/users_controller.rb`
- Modify: `spec/requests/api/v1/admin/users_spec.rb` (append)

- [ ] **Step 1: Append failing tests**

Append to `spec/requests/api/v1/admin/users_spec.rb`:

```ruby
  describe "PUT /api/v1/admin/users/:id/email" do
    let!(:user) { create(:user, email: "old@example.com") }

    it "updates email without sending a confirmation email" do
      ActionMailer::Base.deliveries.clear

      put "/api/v1/admin/users/#{user.id}/email",
          params: { email: "new@example.com" },
          headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.email).to eq("new@example.com")
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "returns 409 email_taken on conflict" do
      create(:user, email: "taken@example.com")

      put "/api/v1/admin/users/#{user.id}/email",
          params: { email: "taken@example.com" },
          headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("email_taken")
    end

    it "logs an audit entry" do
      expect {
        put "/api/v1/admin/users/#{user.id}/email",
            params: { email: "audited@example.com" },
            headers: admin_api_headers
      }.to change(AuditLog, :count).by(1)

      audit = AuditLog.last
      expect(audit.slug).to eq("update_user_email")
      expect(audit.data).to include(
        "target_user_id" => user.id,
        "old_email" => "old@example.com",
        "new_email" => "audited@example.com",
      )
    end

    it "rejects malformed email" do
      put "/api/v1/admin/users/#{user.id}/email",
          params: { email: "not-an-email" },
          headers: admin_api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("validation_failed")
    end
  end
```

- [ ] **Step 2: Run to confirm failure**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb -e "/email"`
Expected: failures (action missing).

- [ ] **Step 3: Add the action**

Append to the concern (after `update`):

```ruby
def update_email
  @user_record = User.find(params[:id])
  new_email = params.require(:email)
  old_email = @user_record.email

  if new_email !~ URI::MailTo::EMAIL_REGEXP
    raise Api::Admin::ApiError.new(:validation_failed, "Email is invalid", status: 422)
  end
  if User.where.not(id: @user_record.id).exists?(email: new_email)
    raise Api::Admin::ApiError.new(:email_taken, "Email already in use", status: 409)
  end

  @user_record.update_columns(email: new_email)
  audit!(slug: "update_user_email",
         data: { "target_user_id" => @user_record.id, "old_email" => old_email, "new_email" => new_email })
  render json: { id: @user_record.id, email: new_email }
end
```

- [ ] **Step 4: Run to verify**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb -e "/email"`
Expected: 4 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/concerns/api/admin/users_controller.rb spec/requests/api/v1/admin/users_spec.rb
git commit -m "Add PUT /api/v1/admin/users/:id/email"
```

---

## Task 9: Users `update_status` — moderation status via ManageActivityAndRoles

**Files:**
- Modify: `app/controllers/concerns/api/admin/users_controller.rb`
- Modify: `spec/requests/api/v1/admin/users_spec.rb` (append)

- [ ] **Step 1: Append failing tests**

```ruby
  describe "PUT /api/v1/admin/users/:id/status" do
    let!(:target) { create(:user) }

    %w[Suspended Spam Warned Trusted Limited].each do |status|
      it "applies #{status}" do
        put "/api/v1/admin/users/#{target.id}/status",
            params: { status: status, note: "for testing" },
            headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        target.reload
        case status
        when "Suspended" then expect(target.suspended?).to be true
        when "Spam"      then expect(target.spam?).to be true
        when "Warned"    then expect(target.warned?).to be true
        when "Trusted"   then expect(target.has_role?(:trusted)).to be true
        when "Limited"   then expect(target.has_role?(:limited)).to be true
        end
      end
    end

    it "applies Good standing (clears moderation roles)" do
      target.add_role(:suspended)
      put "/api/v1/admin/users/#{target.id}/status",
          params: { status: "Good standing", note: "rehab" },
          headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      expect(target.reload.suspended?).to be false
    end

    it "rejects invalid status" do
      put "/api/v1/admin/users/#{target.id}/status",
          params: { status: "Banishedish" }, headers: admin_api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("invalid_status")
    end

    it "rejects role-grant statuses (Admin, Super Moderator, Tech Admin)" do
      put "/api/v1/admin/users/#{target.id}/status",
          params: { status: "Admin" }, headers: admin_api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("invalid_status")
    end

    it "audits the change" do
      expect {
        put "/api/v1/admin/users/#{target.id}/status",
            params: { status: "Suspended", note: "auditable" }, headers: admin_api_headers
      }.to change(AuditLog, :count).by(1)
      audit = AuditLog.last
      expect(audit.slug).to eq("update_user_status")
      expect(audit.data).to include("target_user_id" => target.id, "new_status" => "Suspended")
    end
  end
```

- [ ] **Step 2: Run to confirm failure**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb -e "/status"`
Expected: failures (action missing).

- [ ] **Step 3: Add the action**

Append to the concern:

```ruby
ALLOWED_STATUSES = [
  "Good standing", "Suspended", "Spam", "Warned",
  "Comment Suspended", "Trusted", "Limited"
].freeze

def update_status
  @user_record = User.find(params[:id])
  status = params.require(:status)
  unless ALLOWED_STATUSES.include?(status)
    raise Api::Admin::ApiError.new(:invalid_status, "Status not allowed", status: 422)
  end

  old_status = current_moderation_status(@user_record)
  Moderator::ManageActivityAndRoles.handle_user_roles(
    admin: current_user,
    user: @user_record,
    user_params: { user_status: status, note_for_current_role: params[:note].to_s },
  )

  audit!(slug: "update_user_status",
         data: {
           "target_user_id" => @user_record.id,
           "old_status" => old_status,
           "new_status" => status,
           "note" => params[:note].to_s
         })
  render json: { id: @user_record.id, status: status }
end

def current_moderation_status(user)
  return "Suspended" if user.suspended?
  return "Spam" if user.spam?
  return "Warned" if user.warned?
  return "Comment Suspended" if user.comment_suspended?
  return "Limited" if user.has_role?(:limited)
  return "Trusted" if user.has_role?(:trusted)
  "Good standing"
end
```

- [ ] **Step 4: Run to verify**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb -e "/status"`
Expected: 9 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/concerns/api/admin/users_controller.rb spec/requests/api/v1/admin/users_spec.rb
git commit -m "Add PUT /api/v1/admin/users/:id/status"
```

---

## Task 10: Users `merge` — synchronous merge via Moderator::MergeUser

**Files:**
- Modify: `app/controllers/concerns/api/admin/users_controller.rb`
- Create: `app/views/api/v1/admin/users/merge.json.jbuilder`
- Modify: `spec/requests/api/v1/admin/users_spec.rb` (append)

- [ ] **Step 1: Append failing tests**

```ruby
  describe "POST /api/v1/admin/users/:id/merge" do
    let!(:keeper) { create(:user) }
    let!(:loser)  { create(:user) }

    it "merges loser into keeper end-to-end" do
      article = create(:article, user: loser)
      comment = create(:comment, user: loser)

      post "/api/v1/admin/users/#{keeper.id}/merge",
           params: { merge_user_id: loser.id },
           headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      expect(article.reload.user_id).to eq(keeper.id)
      expect(comment.reload.user_id).to eq(keeper.id)
    end

    it "returns 409 cannot_merge_user_into_itself when ids match" do
      post "/api/v1/admin/users/#{keeper.id}/merge",
           params: { merge_user_id: keeper.id }, headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("cannot_merge_user_into_itself")
    end

    it "returns 409 merge_identity_conflict when MergeUser raises" do
      create(:identity, user: loser, provider: "github", uid: "1")
      create(:identity, user: loser, provider: "twitter", uid: "2")

      post "/api/v1/admin/users/#{keeper.id}/merge",
           params: { merge_user_id: loser.id }, headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("merge_identity_conflict")
    end

    it "audits the merge" do
      expect {
        post "/api/v1/admin/users/#{keeper.id}/merge",
             params: { merge_user_id: loser.id }, headers: admin_api_headers
      }.to change(AuditLog, :count).by(1)
      audit = AuditLog.last
      expect(audit.slug).to eq("merge_users")
      expect(audit.data).to include("keep_user_id" => keeper.id, "deleted_user_id" => loser.id)
    end
  end
```

- [ ] **Step 2: Run to confirm failure**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb -e "merge"`
Expected: failures (action missing).

- [ ] **Step 3: Add the action**

```ruby
def merge
  @user_record = User.find(params[:id])
  delete_id = params.require(:merge_user_id).to_i

  if delete_id == @user_record.id
    raise Api::Admin::ApiError.new(
      :cannot_merge_user_into_itself,
      "Cannot merge a user into itself",
      status: 409,
    )
  end

  begin
    Moderator::MergeUser.call(
      admin: current_user, keep_user: @user_record, delete_user_id: delete_id,
    )
  rescue StandardError => e
    raise Api::Admin::ApiError.new(:merge_identity_conflict, e.message, status: 409)
  end

  audit!(slug: "merge_users",
         data: { "keep_user_id" => @user_record.id, "deleted_user_id" => delete_id })
end
```

- [ ] **Step 4: Create merge.json.jbuilder**

Create `app/views/api/v1/admin/users/merge.json.jbuilder`:

```ruby
json.partial!("api/v1/admin/users/user", user: @user_record)
```

- [ ] **Step 5: Run to verify**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb -e "merge"`
Expected: 4 examples, 0 failures.

- [ ] **Step 6: Run full users spec**

Run: `bundle exec rspec spec/requests/api/v1/admin/users_spec.rb`
Expected: all examples (~28) pass.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/concerns/api/admin/users_controller.rb \
        app/views/api/v1/admin/users/merge.json.jbuilder \
        spec/requests/api/v1/admin/users_spec.rb
git commit -m "Add POST /api/v1/admin/users/:id/merge"
```

---

## Task 11: Notes — `index` and `create`

**Files:**
- Create: `app/controllers/concerns/api/admin/user_notes_controller.rb`
- Create: `app/controllers/api/v1/admin/user_notes_controller.rb`
- Create: `app/views/api/v1/admin/user_notes/index.json.jbuilder`
- Create: `app/views/api/v1/admin/user_notes/create.json.jbuilder`
- Create: `app/views/api/v1/admin/user_notes/_note.json.jbuilder`
- Test: `spec/requests/api/v1/admin/user_notes_spec.rb`

- [ ] **Step 1: Write the failing tests**

Create `spec/requests/api/v1/admin/user_notes_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Api::V1::Admin::UserNotes", type: :request do
  before { Audit::Subscribe.listen :admin_api }
  after  { Audit::Subscribe.forget :admin_api }

  let!(:user) { create(:user) }

  describe "GET /api/v1/admin/users/:user_id/notes" do
    it "lists notes newest first" do
      caller = create(:user, :super_admin)
      old = Note.create!(noteable: user, author: caller, reason: "misc_note", content: "older", created_at: 2.days.ago)
      new_note = Note.create!(noteable: user, author: caller, reason: "misc_note", content: "newer", created_at: 1.day.ago)

      get "/api/v1/admin/users/#{user.id}/notes", headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["notes"].map { |n| n["id"] }
      expect(ids).to eq([new_note.id, old.id])
    end

    it "returns 404 for missing user" do
      get "/api/v1/admin/users/999999/notes", headers: admin_api_headers
      expect(response).to have_http_status(:not_found)
    end

    it "rejects unauth callers" do
      get "/api/v1/admin/users/#{user.id}/notes"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/admin/users/:user_id/notes" do
    it "creates a note with default reason and the api caller as author" do
      caller_user = create(:user, :super_admin)
      headers = admin_api_headers(user: caller_user)

      expect {
        post "/api/v1/admin/users/#{user.id}/notes",
             params: { content: "spotted spam pattern" }, headers: headers
      }.to change(Note, :count).by(1)

      expect(response).to have_http_status(:created)
      note = Note.last
      expect(note.noteable).to eq(user)
      expect(note.author).to eq(caller_user)
      expect(note.reason).to eq("misc_note")
      expect(note.content).to eq("spotted spam pattern")
    end

    it "accepts a custom reason" do
      post "/api/v1/admin/users/#{user.id}/notes",
           params: { content: "x", reason: "core_sync" }, headers: admin_api_headers

      expect(response).to have_http_status(:created)
      expect(Note.last.reason).to eq("core_sync")
    end

    it "audits the creation without leaking content" do
      expect {
        post "/api/v1/admin/users/#{user.id}/notes",
             params: { content: "secret" }, headers: admin_api_headers
      }.to change(AuditLog, :count).by(1)

      audit = AuditLog.last
      expect(audit.slug).to eq("add_user_note")
      expect(audit.data).to include("target_user_id" => user.id, "reason" => "misc_note")
      expect(audit.data["content"]).to be_nil
    end

    it "returns 422 on missing content" do
      post "/api/v1/admin/users/#{user.id}/notes", params: {}, headers: admin_api_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

- [ ] **Step 2: Run to confirm failure**

Run: `bundle exec rspec spec/requests/api/v1/admin/user_notes_spec.rb`
Expected: all FAIL with route or controller errors.

- [ ] **Step 3: Implement concern**

Create `app/controllers/concerns/api/admin/user_notes_controller.rb`:

```ruby
module Api
  module Admin
    module UserNotesController
      extend ActiveSupport::Concern

      DEFAULT_REASON = "misc_note".freeze

      def index
        target = User.find(params[:user_id])
        @notes = target.notes.order(created_at: :desc)
      end

      def create
        target = User.find(params[:user_id])
        content = params.require(:content)
        reason = params[:reason].presence || DEFAULT_REASON

        @note = Note.create!(
          noteable: target, author: current_user, content: content, reason: reason,
        )
        audit!(slug: "add_user_note",
               data: { "target_user_id" => target.id, "note_id" => @note.id, "reason" => reason })
      end
    end
  end
end
```

- [ ] **Step 4: Implement V1 wrapper**

Create `app/controllers/api/v1/admin/user_notes_controller.rb`:

```ruby
module Api
  module V1
    module Admin
      class UserNotesController < BaseController
        include Api::Admin::UserNotesController
      end
    end
  end
end
```

- [ ] **Step 5: Implement views**

Create `app/views/api/v1/admin/user_notes/_note.json.jbuilder`:

```ruby
json.id note.id
json.content note.content
json.reason note.reason
json.author_id note.author_id
json.created_at note.created_at
```

Create `app/views/api/v1/admin/user_notes/index.json.jbuilder`:

```ruby
json.notes(@notes) do |note|
  json.partial!("api/v1/admin/user_notes/note", note: note)
end
```

Create `app/views/api/v1/admin/user_notes/create.json.jbuilder`:

```ruby
json.partial!("api/v1/admin/user_notes/note", note: @note)
```

- [ ] **Step 6: Set the response status for create**

In Rails, `render` from a JBuilder template is implicit. To return `201` from `create`, add `head :created` is wrong because we want a body. Instead, override the status in the controller. Modify the `create` action:

```ruby
def create
  target = User.find(params[:user_id])
  content = params.require(:content)
  reason = params[:reason].presence || DEFAULT_REASON

  @note = Note.create!(
    noteable: target, author: current_user, content: content, reason: reason,
  )
  audit!(slug: "add_user_note",
         data: { "target_user_id" => target.id, "note_id" => @note.id, "reason" => reason })
  render :create, status: :created
end
```

- [ ] **Step 7: Run to verify**

Run: `bundle exec rspec spec/requests/api/v1/admin/user_notes_spec.rb`
Expected: 8 examples, 0 failures.

- [ ] **Step 8: Commit**

```bash
git add app/controllers/concerns/api/admin/user_notes_controller.rb \
        app/controllers/api/v1/admin/user_notes_controller.rb \
        app/views/api/v1/admin/user_notes/ \
        spec/requests/api/v1/admin/user_notes_spec.rb
git commit -m "Add admin API user notes endpoints"
```

---

## Task 12: Identities `index` — list user identities

**Files:**
- Create: `app/controllers/concerns/api/admin/user_identities_controller.rb`
- Create: `app/controllers/api/v1/admin/user_identities_controller.rb`
- Create: `app/views/api/v1/admin/user_identities/index.json.jbuilder`
- (`_identity.json.jbuilder` was created in Task 5; it stays.)
- Test: `spec/requests/api/v1/admin/user_identities_spec.rb`

- [ ] **Step 1: Write failing tests**

Create `spec/requests/api/v1/admin/user_identities_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Api::V1::Admin::UserIdentities", type: :request do
  before { Audit::Subscribe.listen :admin_api }
  after  { Audit::Subscribe.forget :admin_api }

  let!(:user) { create(:user) }

  describe "GET /api/v1/admin/users/:user_id/identities" do
    it "returns identities without leaking secrets" do
      identity = create(:identity, user: user, provider: "mlh", uid: "core-1",
                                   token: "topsecret", secret: "alsosecret")

      get "/api/v1/admin/users/#{user.id}/identities", headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body["identities"].first
      expect(payload).to include("id" => identity.id, "provider" => "mlh", "uid" => "core-1")
      expect(payload.keys).not_to include("token", "secret", "auth_data_dump")
    end

    it "returns [] for users without identities" do
      get "/api/v1/admin/users/#{user.id}/identities", headers: admin_api_headers
      expect(response.parsed_body["identities"]).to eq([])
    end

    it "404s for missing user" do
      get "/api/v1/admin/users/999999/identities", headers: admin_api_headers
      expect(response).to have_http_status(:not_found)
    end

    it "401s without api key" do
      get "/api/v1/admin/users/#{user.id}/identities"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

- [ ] **Step 2: Run to confirm failure**

Run: `bundle exec rspec spec/requests/api/v1/admin/user_identities_spec.rb`
Expected: all FAIL.

- [ ] **Step 3: Implement concern with `index`**

Create `app/controllers/concerns/api/admin/user_identities_controller.rb`:

```ruby
module Api
  module Admin
    module UserIdentitiesController
      extend ActiveSupport::Concern

      def index
        target = User.find(params[:user_id])
        @identities = target.identities.order(created_at: :asc)
      end
    end
  end
end
```

- [ ] **Step 4: Implement V1 wrapper**

Create `app/controllers/api/v1/admin/user_identities_controller.rb`:

```ruby
module Api
  module V1
    module Admin
      class UserIdentitiesController < BaseController
        include Api::Admin::UserIdentitiesController
      end
    end
  end
end
```

- [ ] **Step 5: Implement view**

Create `app/views/api/v1/admin/user_identities/index.json.jbuilder`:

```ruby
json.identities(@identities) do |identity|
  json.partial!("api/v1/admin/user_identities/identity", identity: identity)
end
```

- [ ] **Step 6: Run to verify**

Run: `bundle exec rspec spec/requests/api/v1/admin/user_identities_spec.rb`
Expected: 4 examples, 0 failures.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/concerns/api/admin/user_identities_controller.rb \
        app/controllers/api/v1/admin/user_identities_controller.rb \
        app/views/api/v1/admin/user_identities/index.json.jbuilder \
        spec/requests/api/v1/admin/user_identities_spec.rb
git commit -m "Add GET /api/v1/admin/users/:user_id/identities"
```

---

## Task 13: Identity `create` — strict-fail-closed link

**Files:**
- Modify: `app/controllers/concerns/api/admin/user_identities_controller.rb`
- Create: `app/views/api/v1/admin/user_identities/create.json.jbuilder`
- Modify: `spec/requests/api/v1/admin/user_identities_spec.rb` (append)

- [ ] **Step 1: Append failing tests**

```ruby
  describe "POST /api/v1/admin/users/:user_id/identities" do
    it "creates a new identity (state 1: clean)" do
      expect {
        post "/api/v1/admin/users/#{user.id}/identities",
             params: { provider: "mlh", uid: "core-12345" }, headers: admin_api_headers
      }.to change { user.reload.identities.count }.by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include("provider" => "mlh", "uid" => "core-12345")
    end

    it "is idempotent for the same (user, provider, uid) (state 2)" do
      create(:identity, user: user, provider: "mlh", uid: "core-12345")

      expect {
        post "/api/v1/admin/users/#{user.id}/identities",
             params: { provider: "mlh", uid: "core-12345" }, headers: admin_api_headers
      }.not_to change { Identity.count }

      expect(response).to have_http_status(:ok)
    end

    it "409s when user has different uid for same provider (state 3)" do
      create(:identity, user: user, provider: "mlh", uid: "core-old")

      post "/api/v1/admin/users/#{user.id}/identities",
           params: { provider: "mlh", uid: "core-new" }, headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("user_already_has_identity_for_provider")
    end

    it "409s when (provider, uid) is already linked elsewhere (state 4)" do
      other = create(:user)
      create(:identity, user: other, provider: "mlh", uid: "core-shared")

      post "/api/v1/admin/users/#{user.id}/identities",
           params: { provider: "mlh", uid: "core-shared" }, headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("identity_uid_taken")
    end

    it "422s on unknown provider" do
      post "/api/v1/admin/users/#{user.id}/identities",
           params: { provider: "doesnotexist", uid: "x" }, headers: admin_api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("unknown_provider")
    end

    it "sets user.<provider>_username when 'username' param is provided" do
      post "/api/v1/admin/users/#{user.id}/identities",
           params: { provider: "mlh", uid: "core-12345", username: "jane_mlh" },
           headers: admin_api_headers

      expect(user.reload.mlh_username).to eq("jane_mlh")
    end

    it "audits the link" do
      expect {
        post "/api/v1/admin/users/#{user.id}/identities",
             params: { provider: "mlh", uid: "audited" }, headers: admin_api_headers
      }.to change(AuditLog, :count).by(1)

      audit = AuditLog.last
      expect(audit.slug).to eq("link_identity")
      expect(audit.data).to include("provider" => "mlh", "uid" => "audited", "target_user_id" => user.id)
    end
  end
```

- [ ] **Step 2: Run to confirm failure**

Run: `bundle exec rspec spec/requests/api/v1/admin/user_identities_spec.rb -e "POST"`
Expected: failures.

- [ ] **Step 3: Implement create**

Append to `app/controllers/concerns/api/admin/user_identities_controller.rb`:

```ruby
def create
  target = User.find(params[:user_id])
  provider = params.require(:provider)
  uid = params.require(:uid).to_s

  unless Authentication::Providers.available.map(&:to_s).include?(provider)
    raise Api::Admin::ApiError.new(:unknown_provider,
                                   "Provider '#{provider}' is not configured",
                                   status: 422)
  end

  ActiveRecord::Base.transaction do
    existing_for_user = target.identities.find_by(provider: provider)
    if existing_for_user
      if existing_for_user.uid == uid
        @identity = existing_for_user
        # Idempotent — set provider username if it was missing and we got one.
        update_provider_username(target, provider, params[:username]) if params[:username].present?
        return render :create, status: :ok
      else
        raise Api::Admin::ApiError.new(
          :user_already_has_identity_for_provider,
          "User already has identity for provider '#{provider}'",
          status: 409,
        )
      end
    end

    if Identity.exists?(provider: provider, uid: uid)
      raise Api::Admin::ApiError.new(
        :identity_uid_taken,
        "Identity uid #{uid} (#{provider}) is already linked to another user",
        status: 409,
      )
    end

    @identity = Identity.create!(user: target, provider: provider, uid: uid)
    update_provider_username(target, provider, params[:username]) if params[:username].present?
  end

  audit!(slug: "link_identity",
         data: {
           "target_user_id" => target.id,
           "identity_id" => @identity.id,
           "provider" => provider,
           "uid" => uid
         })
  render :create, status: :created
end

private

def update_provider_username(user, provider, username)
  field = "#{provider}_username"
  return unless user.respond_to?("#{field}=")

  user.update_column(field, username)
end
```

- [ ] **Step 4: Implement view**

Create `app/views/api/v1/admin/user_identities/create.json.jbuilder`:

```ruby
json.partial!("api/v1/admin/user_identities/identity", identity: @identity)
```

- [ ] **Step 5: Run to verify**

Run: `bundle exec rspec spec/requests/api/v1/admin/user_identities_spec.rb -e "POST"`
Expected: 7 examples, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/concerns/api/admin/user_identities_controller.rb \
        app/views/api/v1/admin/user_identities/create.json.jbuilder \
        spec/requests/api/v1/admin/user_identities_spec.rb
git commit -m "Add POST /api/v1/admin/users/:user_id/identities (strict link)"
```

---

## Task 14: Identity `destroy` — unlink with side effects

**Files:**
- Modify: `app/controllers/concerns/api/admin/user_identities_controller.rb`
- Modify: `spec/requests/api/v1/admin/user_identities_spec.rb` (append)

- [ ] **Step 1: Append failing tests**

```ruby
  describe "DELETE /api/v1/admin/users/:user_id/identities/:id" do
    let!(:identity) { create(:identity, user: user, provider: "mlh", uid: "core-1") }

    before { user.update_column(:mlh_username, "jane_mlh") }

    it "destroys the identity and nulls user.<provider>_username" do
      expect {
        delete "/api/v1/admin/users/#{user.id}/identities/#{identity.id}", headers: admin_api_headers
      }.to change(Identity, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(user.reload.mlh_username).to be_nil
    end

    it "destroys github_repos when unlinking github" do
      gh = create(:identity, user: user, provider: "github", uid: "gh-1")
      create(:github_repo, user: user)

      expect {
        delete "/api/v1/admin/users/#{user.id}/identities/#{gh.id}", headers: admin_api_headers
      }.to change(GithubRepo, :count).by(-1)
    end

    it "404s when identity does not belong to user" do
      other = create(:user)
      foreign = create(:identity, user: other, provider: "mlh", uid: "core-2")

      delete "/api/v1/admin/users/#{user.id}/identities/#{foreign.id}", headers: admin_api_headers
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error_code"]).to eq("identity_not_found")
    end

    it "audits the unlink" do
      expect {
        delete "/api/v1/admin/users/#{user.id}/identities/#{identity.id}", headers: admin_api_headers
      }.to change(AuditLog, :count).by(1)
      audit = AuditLog.last
      expect(audit.slug).to eq("unlink_identity")
      expect(audit.data).to include("provider" => "mlh", "uid" => "core-1", "identity_id" => identity.id)
    end
  end
```

- [ ] **Step 2: Run to confirm failure**

Run: `bundle exec rspec spec/requests/api/v1/admin/user_identities_spec.rb -e "DELETE"`
Expected: failures.

- [ ] **Step 3: Implement destroy**

Append to the concern (above the existing `private`):

```ruby
def destroy
  target = User.find(params[:user_id])
  identity = target.identities.find_by(id: params[:id])
  unless identity
    raise Api::Admin::ApiError.new(
      :identity_not_found, "Identity not found for user", status: 404,
    )
  end

  provider = identity.provider
  uid = identity.uid
  identity_id = identity.id

  identity.destroy!
  update_provider_username(target, provider, nil)
  target.github_repos.destroy_all if provider.to_sym == :github

  audit!(slug: "unlink_identity",
         data: {
           "target_user_id" => target.id,
           "identity_id" => identity_id,
           "provider" => provider,
           "uid" => uid
         })
  head :no_content
end
```

`update_provider_username` was added in Task 13; reuse it. The `nil` argument should null out the field — but `update_column` won't do that with `nil`. Update the helper:

```ruby
def update_provider_username(user, provider, username)
  field = "#{provider}_username"
  return unless user.respond_to?("#{field}=")

  user.update_column(field, username)
end
```

This already handles `nil` (passes it straight through to `update_column`). Verify by reviewing.

- [ ] **Step 4: Run to verify**

Run: `bundle exec rspec spec/requests/api/v1/admin/user_identities_spec.rb -e "DELETE"`
Expected: 4 examples, 0 failures.

- [ ] **Step 5: Run full identities spec**

Run: `bundle exec rspec spec/requests/api/v1/admin/user_identities_spec.rb`
Expected: 15 examples, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/concerns/api/admin/user_identities_controller.rb spec/requests/api/v1/admin/user_identities_spec.rb
git commit -m "Add DELETE /api/v1/admin/users/:user_id/identities/:id"
```

---

## Task 15: OAuth callback round-trip integration spec

This task verifies (and locks in via test) that an API-pre-created `Identity` is reused — not duplicated — when the corresponding OAuth login happens. If the test fails, the implementation plan is incomplete and needs a follow-up to fix the OAuth callback path.

**Files:**
- Create: `spec/requests/authenticator_api_link_round_trip_spec.rb`

- [ ] **Step 1: Write the spec**

Create `spec/requests/authenticator_api_link_round_trip_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "API-linked identity round-trips through OAuth login", type: :request do
  it "reuses an API-pre-created Identity row on first OAuth login (no duplicate user, no duplicate identity)" do
    target = create(:user)
    secret = create(:api_secret, user: create(:user, :super_admin)).secret

    # Pre-link via API
    post "/api/v1/admin/users/#{target.id}/identities",
         params: { provider: "mlh", uid: "core-roundtrip", username: "rt_user" },
         headers: { "api-key" => secret }
    expect(response).to have_http_status(:created)
    pre_existing_id = Identity.find_by!(provider: "mlh", uid: "core-roundtrip").id

    # Build the omniauth payload that MyMLH would send.
    auth_payload = OmniAuth::AuthHash.new(
      provider: "mlh",
      uid: "core-roundtrip",
      info: OmniAuth::AuthHash::InfoHash.new(
        email: target.email, name: target.name, nickname: "rt_user",
      ),
      credentials: OmniAuth::AuthHash.new(token: "tok", secret: "sec"),
      extra: OmniAuth::AuthHash.new(raw_info: OmniAuth::AuthHash.new(created_at: Time.current.iso8601)),
    )

    expect {
      authed = Authentication::Authenticator.call(auth_payload, current_user: nil)
      expect(authed.id).to eq(target.id)
    }.not_to change(User, :count)

    expect(Identity.where(provider: "mlh", uid: "core-roundtrip").count).to eq(1)
    expect(Identity.find(pre_existing_id).user_id).to eq(target.id)
    expect(Identity.find(pre_existing_id).token).to eq("tok")
  end
end
```

- [ ] **Step 2: Run the spec**

Run: `bundle exec rspec spec/requests/authenticator_api_link_round_trip_spec.rb`
Expected: PASS. (The `Authentication::Authenticator` already supports this — see `app/services/authentication/authenticator.rb` lines 47–66 and `Identity.build_from_omniauth` using `find_or_initialize_by(provider:, uid:)`.)

If it FAILS, the failure is the canary that the OAuth callback does not round-trip. **Stop and surface the failure to the human reviewer** rather than patching around it — fixing the OAuth callback is a separate, larger change.

- [ ] **Step 3: Commit**

```bash
git add spec/requests/authenticator_api_link_round_trip_spec.rb
git commit -m "Add OAuth callback round-trip spec for API-pre-linked identities"
```

---

## Task 16: i18n locale strings

The error messages and audit slugs we emit are mostly machine-readable, but a few human-facing message strings should be localized per AGENTS.md.

**Files:**
- Modify: `config/locales/en.yml`
- Modify: `config/locales/fr.yml`
- Modify: `config/locales/pt.yml`

The strings to add (English):

```yaml
admin_api:
  errors:
    user_not_found: "User not found"
    identity_not_found: "Identity not found for user"
    user_already_has_identity_for_provider: "User already has an identity for provider '%{provider}'"
    identity_uid_taken: "Identity uid %{uid} (%{provider}) is already linked to another user"
    cannot_merge_user_into_itself: "Cannot merge a user into itself"
    merge_identity_conflict: "Merge could not complete: %{reason}"
    unknown_provider: "Provider '%{provider}' is not configured"
    invalid_status: "Status not allowed"
    email_taken: "Email already in use"
    validation_failed: "Validation failed"
```

- [ ] **Step 1: Inspect existing locale layout**

Run: `grep -n "^[a-z]\+:" config/locales/en.yml | head -10`
Expected: top-level keys list — find an appropriate place to add `admin_api:` (alphabetical).

- [ ] **Step 2: Add the keys to en.yml**

Open `config/locales/en.yml` and add the `admin_api:` block at the appropriate alphabetical position under the top-level `en:` key.

- [ ] **Step 3: Add to fr.yml and pt.yml**

In each, mirror the structure but provide rough translations. Example fr:

```yaml
admin_api:
  errors:
    user_not_found: "Utilisateur introuvable"
    identity_not_found: "Identité introuvable pour cet utilisateur"
    user_already_has_identity_for_provider: "L'utilisateur a déjà une identité pour le fournisseur « %{provider} »"
    identity_uid_taken: "L'uid %{uid} (%{provider}) est déjà lié à un autre utilisateur"
    cannot_merge_user_into_itself: "Impossible de fusionner un utilisateur avec lui-même"
    merge_identity_conflict: "La fusion n'a pas pu être effectuée : %{reason}"
    unknown_provider: "Le fournisseur « %{provider} » n'est pas configuré"
    invalid_status: "Statut non autorisé"
    email_taken: "Adresse e-mail déjà utilisée"
    validation_failed: "La validation a échoué"
```

Example pt:

```yaml
admin_api:
  errors:
    user_not_found: "Usuário não encontrado"
    identity_not_found: "Identidade não encontrada para o usuário"
    user_already_has_identity_for_provider: "O usuário já possui uma identidade para o provedor '%{provider}'"
    identity_uid_taken: "O uid %{uid} (%{provider}) já está vinculado a outro usuário"
    cannot_merge_user_into_itself: "Não é possível mesclar um usuário consigo mesmo"
    merge_identity_conflict: "A mesclagem não pôde ser concluída: %{reason}"
    unknown_provider: "O provedor '%{provider}' não está configurado"
    invalid_status: "Status não permitido"
    email_taken: "E-mail já utilizado"
    validation_failed: "A validação falhou"
```

- [ ] **Step 4: Wire the translations into the controllers (optional refinement)**

The current controller code uses inline English strings. To use the locale strings, replace the hardcoded messages. Example, in `user_identities_controller.rb`'s create action:

```ruby
raise Api::Admin::ApiError.new(
  :unknown_provider,
  I18n.t("admin_api.errors.unknown_provider", provider: provider),
  status: 422,
)
```

Apply the same pattern to all `Api::Admin::ApiError` raises across the three concerns. Re-run all the spec files to confirm nothing broke (the specs match on `error_code`, not exact `error` strings, so this should not break tests).

- [ ] **Step 5: Verify all locale files load cleanly**

Run: `bundle exec rails runner 'puts I18n.t("admin_api.errors.user_not_found")'`
Expected: prints the English string with no `translation missing` warning.

Run: `bundle exec rails runner 'I18n.locale = :fr; puts I18n.t("admin_api.errors.user_not_found")'`
Expected: prints the French string.

Run: `bundle exec rails runner 'I18n.locale = :pt; puts I18n.t("admin_api.errors.user_not_found")'`
Expected: prints the Portuguese string.

- [ ] **Step 6: Run the full test suite**

Run: `bundle exec rspec spec/requests/api/v1/admin/ spec/requests/authenticator_api_link_round_trip_spec.rb spec/routing/api/v1/admin_routes_spec.rb spec/errors/api/admin/api_error_spec.rb`
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add config/locales/en.yml config/locales/fr.yml config/locales/pt.yml \
        app/controllers/concerns/api/admin/users_controller.rb \
        app/controllers/concerns/api/admin/user_notes_controller.rb \
        app/controllers/concerns/api/admin/user_identities_controller.rb
git commit -m "Localize admin API error messages (en, fr, pt)"
```

---

## Task 17: Final verification + runbook stub

**Files:**
- Create: `docs/admin-api-runbook.md`

- [ ] **Step 1: Run the full admin API test suite once more**

Run: `bundle exec rspec spec/requests/api/v1/admin/ spec/requests/authenticator_api_link_round_trip_spec.rb spec/routing/api/v1/admin_routes_spec.rb spec/errors/api/admin/api_error_spec.rb`
Expected: all green. Note total example count (~50+).

- [ ] **Step 2: Run RuboCop on touched files**

Run: `bundle exec rubocop app/controllers/api/v1/admin/ app/controllers/concerns/api/admin/ app/errors/api/admin/ app/views/api/v1/admin/ spec/requests/api/v1/admin/`
Expected: no offenses. Fix any reported.

- [ ] **Step 3: Write the runbook**

Create `docs/admin-api-runbook.md`:

```markdown
# Admin API — Operations Runbook

## Creating a service account for MLH Core

1. In a Rails console (production), create a dedicated super_admin user:

   ```ruby
   user = User.create!(
     email: "core-service@mlh.io",
     username: "core_service",
     name: "MLH Core Service Account",
     password: SecureRandom.hex(32),
     password_confirmation: SecureRandom.hex(32),
     registered: true, registered_at: Time.current,
   )
   user.skip_confirmation!
   user.save!
   user.add_role(:super_admin)
   ```

2. Generate an API secret for the user:

   ```ruby
   secret = ApiSecret.create!(user: user, description: "MLH Core sync — initial issue")
   puts secret.secret
   ```

3. Store the secret in MLH Core's secrets vault. Rotate by creating a new ApiSecret record and deleting the old one.

## Authentication

All admin API requests must include:

```
api-key: <secret>
Accept: application/vnd.forem.api-v1+json
```

## Audit log

Every successful write emits an `AuditLog` row with `category: "admin_api.audit.log"`. View via the existing admin UI's user audit log tab, or query directly:

```ruby
AuditLog.where(category: "admin_api.audit.log").on_user(user).order(created_at: :desc)
```

## Endpoint reference

See `docs/superpowers/specs/2026-05-02-admin-user-management-api-design.md` for the full endpoint specification.
```

- [ ] **Step 4: Commit**

```bash
git add docs/admin-api-runbook.md
git commit -m "Add admin API operations runbook"
```

---

## Self-review against spec (run at end)

After completing Tasks 1–17, walk through the spec file and verify each requirement is implemented. Specifically:

| Spec section | Implemented in task |
|---|---|
| Endpoints — Users (index, show, update, update_email, update_status, merge) | Tasks 5, 6, 7, 8, 9, 10 |
| Endpoints — Notes (index, create) | Task 11 |
| Endpoints — Identities (index, create, destroy) | Tasks 12, 13, 14 |
| Identity linking strict semantics (states 1–4) | Task 13 |
| Unlink side effects (`<provider>_username` null, github_repos cascade) | Task 14 |
| Audit logging | Tasks 3 + each writing endpoint |
| Error envelope + error code catalog | Task 3 |
| OAuth callback round-trip canary | Task 15 |
| i18n in en/fr/pt | Task 16 |
| Service account runbook | Task 17 |

If any spec requirement has no task, add a follow-up task before declaring complete.

## What's deferred (per spec non-goals)

These are explicitly NOT in this plan:

- Banishing, full-deleting, or unpublishing-all-articles via API
- Async merge with status polling
- Editing `profile_image` or other broad `Profile` fields
- Outbound Forem→Core propagation
- V0 wrappers
- Adding a unique index on `Identity(provider, uid)` — already exists per `db/schema.rb`
- OpenAPI/Swagger regeneration — verify whether Forem maintains one before assuming it does
