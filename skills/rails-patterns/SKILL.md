---
name: rails-patterns
description: Ruby on Rails patterns, ActiveRecord ORM, RESTful APIs, and modern Rails development best practices
---

# Ruby on Rails Development Patterns

## When to Use This Skill

- Building Rails web applications and APIs
- Implementing ActiveRecord models and associations
- Creating RESTful APIs with Rails
- Following Rails conventions and best practices
- Building full-stack Ruby applications

## Target Agents

- `rails-expert` - Primary user for Rails development
- `backend-developer` - General backend development with Rails  
- `api-architect` - REST API design using Rails

## Core Patterns

### 1. Model Associations

```ruby
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments
  has_many :commented_posts, through: :comments, source: :post

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, length: { minimum: 3 }

  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
end

class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :taggings
  has_many :tags, through: :taggings

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true

  scope :published, -> { where(status: 'published') }
end
```

### 2. Controller Patterns

```ruby
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post, only: [:edit, :update, :destroy]

  def index
    @posts = Post.published.includes(:user).page(params[:page])
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to @post, notice: 'Post created successfully'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content, :status, tag_ids: [])
  end

  def authorize_post
    redirect_to root_path unless current_user == @post.user
  end
end
```

### 3. Service Objects

```ruby
class PostPublisher
  attr_reader :post, :user

  def initialize(post, user)
    @post = post
    @user = user
  end

  def call
    return false unless can_publish?

    ActiveRecord::Base.transaction do
      post.update!(status: 'published', published_at: Time.current)
      notify_subscribers
      PostPublishedEvent.trigger(post)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def can_publish?
    user == post.user && post.draft?
  end

  def notify_subscribers
    user.followers.each do |follower|
      PostMailer.new_post_notification(follower, post).deliver_later
    end
  end
end
```

### 4. API Serialization with ActiveModelSerializers

```ruby
class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :excerpt, :published_at
  attribute :content, if: :show_full_content?

  belongs_to :user, serializer: UserSerializer
  has_many :comments, serializer: CommentSerializer

  def excerpt
    object.content.truncate(200)
  end

  def show_full_content?
    scope.present? && (scope == object.user || scope.admin?)
  end
end
```

### 5. Background Jobs with Sidekiq

```ruby
class ImageProcessorJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(post_id, image_path)
    post = Post.find(post_id)
    processed_image = process_image(image_path)
    post.update!(featured_image: processed_image)
  end

  private

  def process_image(path)
    # Image processing logic
  end
end

# Enqueue job
ImageProcessorJob.perform_later(post.id, image_path)
```

### 6. Concerns for Shared Behavior

```ruby
module Publishable
  extend ActiveSupport::Concern

  included do
    scope :published, -> { where(status: 'published') }
    scope :draft, -> { where(status: 'draft') }

    validates :status, inclusion: { in: %w[draft published archived] }
  end

  def publish!
    update!(status: 'published', published_at: Time.current)
  end

  def draft?
    status == 'draft'
  end
end

class Post < ApplicationRecord
  include Publishable
end
```

### 7. Testing with RSpec

```ruby
RSpec.describe PostsController, type: :controller do
  let(:user) { create(:user) }
  let(:post) { create(:post, user: user) }

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new post' do
        expect {
          post :create, params: { post: attributes_for(:post) }
        }.to change(Post, :count).by(1)
      end

      it 'redirects to the new post' do
        post :create, params: { post: attributes_for(:post) }
        expect(response).to redirect_to(Post.last)
      end
    end
  end
end
```

### 8. Query Optimization

```ruby
# N+1 query problem
posts = Post.all
posts.each { |post| puts post.user.name } # N+1!

# Solution: eager loading
posts = Post.includes(:user, :comments)
posts.each { |post| puts post.user.name } # Single query

# Preload vs Includes
Post.preload(:user)     # Separate queries
Post.includes(:user)    # LEFT OUTER JOIN
Post.eager_load(:user)  # Force LEFT OUTER JOIN
```

## Best Practices

1. Follow **Rails conventions**
2. Use **service objects** for complex business logic
3. Implement **concerns** for shared behavior
4. Use **ActiveJob** for background processing
5. Write **comprehensive tests** with RSpec
6. Optimize queries with **includes/preload**
7. Use **strong parameters** for security
8. Implement **authentication and authorization**
9. Follow **RESTful** routing conventions
10. Use **migrations** for database changes
