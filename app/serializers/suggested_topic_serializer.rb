# frozen_string_literal: true

class SuggestedTopicSerializer < ListableTopicSerializer
  include TopicTagsMixin

  # need to embed so we have users
  # front page json gets away without embedding
  class SuggestedPosterSerializer < ApplicationSerializer
    attributes :extras, :description
    has_one :user, serializer: PosterSerializer, embed: :objects
  end

  attributes :archetype,
             :like_count,
             :views,
             :category_id,
             :featured_link,
             :featured_link_root_domain,
             :category,
             :topic_creator,
             :first_post_details

  has_many :posters, serializer: SuggestedPosterSerializer, embed: :objects

  def posters
    object.posters || []
  end

  def include_featured_link?
    SiteSetting.topic_featured_link_enabled
  end

  def featured_link
    object.featured_link
  end

  def include_featured_link_root_domain?
    SiteSetting.topic_featured_link_enabled && object.featured_link
  end

  def category
    {
      id: object.category.id,
      name: object.category&.name,
      topic_title: object.title,
      only_admin_can_post: object.category&.groups&.exists?(name: "admins")
    }
  end

  def topic_creator
    {
      id: object.user&.id,
      username: object.user&.username,
      avatar: object.user&.avatar_template
    }
  end

  def first_post_details
    {
      post_id: object&.first_post&.id,
      bookmark_id: bookmark_id_for_first_post,
      is_post_liked: is_post_liked?,
      is_post_bookmarked: is_post_bookmarked?
    }
  end

  private

    def is_post_liked?
      DiscourseReactions::ReactionUser
      .where(user_id: scope.user&.id, post_id: object&.first_post&.id)
      .exists?
    end

    def is_post_bookmarked?
      object&.first_post&.bookmarks&.where(user_id: scope.user&.id)&.last.present?
    end

    def bookmark_id_for_first_post
      bookmark = object&.first_post&.bookmarks&.where(user_id: scope.user&.id).last
      bookmark&.id
    end
end