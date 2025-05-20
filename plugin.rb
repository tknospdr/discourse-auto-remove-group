# name: discourse-auto-remove-group
# version: 0.3
# authors: David Muszynski
# url: https://github.com/tknospdr/discourse-auto-remove-group

# Define site settings manually for older Discourse versions
add_to_class :site_setting, :auto_remove_group_enabled do
  SiteSetting.get(:auto_remove_group_enabled, false)
end
add_to_class :site_setting, :auto_remove_group_category_id do
  SiteSetting.get(:auto_remove_group_category_id, 0)
end
add_to_class :site_setting, :auto_remove_group_name do
  SiteSetting.get(:auto_remove_group_name, "")
end

after_initialize do
  # Ensure required constants are defined
  next unless defined?(DiscourseEvent) && defined?(SiteSetting) && defined?(Group)

  DiscourseEvent.on(:post_created) do |post|
    # Skip if plugin is disabled or required objects are missing
    next unless SiteSetting.respond_to?(:auto_remove_group_enabled) && SiteSetting.auto_remove_group_enabled
    next unless post&.user
    next unless post&.topic&.category_id

    target_category_id = SiteSetting.respond_to?(:auto_remove_group_category_id) ? SiteSetting.auto_remove_group_category_id : 0
    group_name = SiteSetting.respond_to?(:auto_remove_group_name) ? SiteSetting.auto_remove_group_name : ""

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
