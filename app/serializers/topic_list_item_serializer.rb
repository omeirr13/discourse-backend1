# frozen_string_literal: true

class TopicListItemSerializer < ListableTopicSerializer
  include TopicTagsMixin

  attributes :views,
             :like_count,
             :has_summary,
             :archetype,
             :last_poster_username,
             :category_id,
             :op_like_count,
             :pinned_globally,
             :liked_post_numbers,
             :featured_link,
             :featured_link_root_domain,
             :allowed_user_count,
             :participant_groups,
             :category,
             :topic_creator,
             :cooked,
             :first_post_details

  has_many :posters, serializer: TopicPosterSerializer, embed: :objects
  has_many :participants, serializer: TopicPosterSerializer, embed: :objects

  def include_participant_groups?
    object.private_message?
  end

  def posters
    object.posters || object.posters_summary || []
  end

  def op_like_count
    object.first_post && object.first_post.like_count
  end

  def last_poster_username
    posters.find { |poster| poster.user.id == object.last_post_user_id }.try(:user).try(:username)
  end

  def category_id
    # If it's a shared draft, show the destination topic instead
    if object.includes_destination_category && object.shared_draft
      return object.shared_draft.category_id
    end

    object.category_id
  end

  def category
    {
      id: category_id,
      name: object.category&.name,
      only_admin_can_post: object.category&.groups&.exists?(name: "admins")
    }
  end

  def topic_creator
    {
      id: object.user&.id,
      username: object.user&.username,
      avatar: object.user&.avatar_template,
      topic_title: object.title,
      name: object.user&.name
    }
  end

  def cooked
    object&.first_post&.cooked
  end

  def participants
    object.participants_summary || []
  end

  def participant_groups
    object.participant_groups_summary || []
  end

  def include_liked_post_numbers?
    include_post_action? :like
  end

  def include_post_action?(action)
    object.user_data && object.user_data.post_action_data &&
      object.user_data.post_action_data.key?(PostActionType.types[action])
  end

  def liked_post_numbers
    object.user_data.post_action_data[PostActionType.types[:like]]
  end

  def include_participants?
    object.private_message?
  end

  def include_op_like_count?
    # PERF: long term we probably want a cheaper way of looking stuff up
    # this is rather odd code, but we need to have op_likes loaded somehow
    # simplest optimisation is adding a cache column on topic.
    object.association(:first_post).loaded?
  end

  def include_featured_link?
    SiteSetting.topic_featured_link_enabled
  end

  def include_featured_link_root_domain?
    SiteSetting.topic_featured_link_enabled && object.featured_link.present?
  end

  def allowed_user_count
    # Don't use count as it will result in a query
    object.allowed_users.length
  end

  def include_allowed_user_count?
    object.private_message?
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