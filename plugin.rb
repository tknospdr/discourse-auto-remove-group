# name: discourse-auto-remove-group
# version: 0.1
# authors: David Muszynski
# url: https://github.com/tknospdr/discourse-auto-remove-group

enabled_site_setting :auto_remove_group_enabled

# Site setting to enable/disable the plugin
register_site_setting :auto_remove_group_enabled, type: :boolean, default: true
register_site_setting :auto_remove_group_category_id, type: :integer, default: 15
register_site_setting :auto_remove_group_name, type: :string, default: "marketplace"

after_initialize do
  # Listen for post creation events
  DiscourseEvent.on(:post_created) do |post|
    next unless SiteSetting.auto_remove_group_enabled
    next unless post&.user # Ensure post has a user
    next unless post&.topic&.category_id # Ensure post is in a category

    target_category_id = SiteSetting.auto_remove_group_category_id
    group_name = SiteSetting.auto_remove_group_name

    # Check if the post is in the configured category
    if post.topic.category_id == target_category_id
      begin
        group = Group.find_by(name: group_name)
        unless group
          Rails.logger.error("AutoRemoveGroup: Group '#{group_name}' not found")
          next
        end

        user = post.user
        if group.users.include?(user)
          group.remove(user)
          Rails.logger.info("AutoRemoveGroup: Removed user #{user.username} from group #{group_name} after posting in category #{target_category_id}")
        else
          Rails.logger.info("AutoRemoveGroup: User #{user.username} is not in group #{group_name}, no action taken")
        end
      rescue StandardError => e
        Rails.logger.error("AutoRemoveGroup: Error removing user from group: #{e.message}")
      end
    end
  end
end
