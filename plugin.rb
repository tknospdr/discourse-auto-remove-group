# name: discourse-auto-remove-group
# about: Allows you to remove users from a group after they post in a selected category
# version: 0.4
# authors: David Muszynski
# url: https://github.com/tknospdr/discourse-auto-remove-group

enabled_site_setting :auto_remove_group_enabled

after_initialize do
  # Ensure required constants are defined
  next unless defined?(DiscourseEvent) && defined?(SiteSetting) && defined?(Group)

  DiscourseEvent.on(:post_created) do |post|
    # Skip if plugin is disabled or required objects are missing
    next unless SiteSetting.auto_remove_group_enabled
    next unless post&.user
    next unless post&.topic&.category_id

    target_category_id = SiteSetting.auto_remove_group_category_id
    group_name = SiteSetting.auto_remove_group_name

    # Skip if category or group name is not configured
    next unless target_category_id > 0 && group_name.present?

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
