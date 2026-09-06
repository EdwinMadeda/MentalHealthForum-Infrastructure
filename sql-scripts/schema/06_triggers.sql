-- =====================================================================
-- PART 16: TRIGGERS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 16.1 Category depth validation
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_validate_category_depth
    BEFORE INSERT OR UPDATE ON forum_categories
                         FOR EACH ROW
                         EXECUTE FUNCTION validate_category_depth();

-- ---------------------------------------------------------------------
-- 16.2 Category tags updated_at
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_category_tags_updated_at
    BEFORE UPDATE ON category_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_category_tags_updated_at();

-- ---------------------------------------------------------------------
-- 16.3 Post word count
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_calculate_word_count
    BEFORE INSERT OR UPDATE OF content ON forum_posts
    FOR EACH ROW
    EXECUTE FUNCTION calculate_word_count();

-- ---------------------------------------------------------------------
-- 16.4 Post depth validation
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_validate_post_depth
    BEFORE INSERT OR UPDATE ON forum_posts
                         FOR EACH ROW
                         EXECUTE FUNCTION validate_post_depth();

-- ---------------------------------------------------------------------
-- 16.5 Update thread on post insert
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_update_thread_on_post
    AFTER INSERT ON forum_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_thread_on_post();

-- ---------------------------------------------------------------------
-- 16.6 Update post reaction count
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_update_post_reaction_count
    AFTER INSERT OR DELETE ON post_reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_post_reaction_count();

-- ---------------------------------------------------------------------
-- 16.7 Update author reputation on reaction
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_update_author_reputation
    AFTER INSERT ON post_reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_author_reputation();

-- ---------------------------------------------------------------------
-- 16.8 Report last_modified_at
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_update_last_modified
    BEFORE UPDATE ON content_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_last_modified();

-- ---------------------------------------------------------------------
-- 16.9 Report history audit log
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_update_report_history
    AFTER INSERT OR UPDATE ON content_reports
                        FOR EACH ROW
                        EXECUTE FUNCTION update_report_history();

-- ---------------------------------------------------------------------
-- 16.10 Flag content on report
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_flag_content_on_report
    AFTER INSERT ON content_reports
    FOR EACH ROW
    EXECUTE FUNCTION flag_content_on_report();

-- ---------------------------------------------------------------------
-- 16.11 Report templates updated_at
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_report_templates_updated_at
    BEFORE UPDATE ON report_templates
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE FUNCTION update_report_templates_updated_at();

-- ---------------------------------------------------------------------
-- 16.12 Moderation action templates updated_at
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_moderation_action_templates_updated_at
    BEFORE UPDATE ON moderation_action_templates
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE FUNCTION update_moderation_action_templates_updated_at();

-- ---------------------------------------------------------------------
-- 16.13 Dismissal reason templates updated_at
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_dismissal_reason_templates_updated_at
    BEFORE UPDATE ON dismissal_reason_templates
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE FUNCTION update_moderation_action_templates_updated_at();

-- ---------------------------------------------------------------------
-- 16.14 User connections updated_at
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_update_user_connections_updated_at
    BEFORE UPDATE ON user_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ---------------------------------------------------------------------
-- 16.15 Notify on reply (creates notification)
-- ---------------------------------------------------------------------
CREATE TRIGGER trigger_notify_on_reply
    AFTER INSERT ON forum_posts
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_reply();

-- ---------------------------------------------------------------------
-- 16.16 Prevent admin deactivation
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_admin_deactivation()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the user is an admin or moderator (OLD) or WILL BE an admin (NEW)
    IF (OLD.roles && ARRAY['admin', 'moderator'])
        OR (OLD.groups && ARRAY['/administrators', '/moderators/professional', '/moderators/peer', '/super_administrators'])
        OR (NEW.roles && ARRAY['admin', 'moderator'])
        OR (NEW.groups && ARRAY['/administrators', '/moderators/professional', '/moderators/peer', '/super_administrators'])
    THEN
        -- Prevent deactivation (changing account_status to anything other than ACTIVE)
        IF NEW.account_status != 'ACTIVE' AND NEW.account_status != OLD.account_status THEN
            RAISE EXCEPTION 'Cannot deactivate an admin or moderator user (ID: %)', NEW.keycloak_id;
        END IF;

        -- Prevent deletion request
        IF NEW.deletion_requested_at IS NOT NULL AND OLD.deletion_requested_at IS NULL THEN
            RAISE EXCEPTION 'Cannot mark an admin or moderator user for deletion (ID: %)', NEW.keycloak_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach the trigger to INSERT and UPDATE events
CREATE OR REPLACE TRIGGER trg_prevent_admin_deactivation
BEFORE INSERT OR UPDATE ON app_users
FOR EACH ROW
EXECUTE FUNCTION prevent_admin_deactivation();

-- ---------------------------------------------------------------------
-- 16.17 Prevent admin deletion
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_admin_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the user being deleted is an admin or moderator
    IF (OLD.roles && ARRAY['admin', 'moderator'])
        OR (OLD.groups && ARRAY['/administrators', '/moderators/professional', '/moderators/peer', '/super_administrators'])
    THEN
        RAISE EXCEPTION 'Cannot delete an admin or moderator user (ID: %)', OLD.keycloak_id;
    END IF;

    RETURN OLD; -- Allowed
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 16.18 Check user keycloak uniqueness
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_user_keycloak_uniqueness()
RETURNS TRIGGER AS $$
BEGIN
    -- When inserting into app_users, check if the user is in admin_invitations
    IF TG_TABLE_NAME = 'app_users' AND TG_OP = 'INSERT' THEN
        IF EXISTS (SELECT 1 FROM admin_invitations WHERE keycloak_id = NEW.keycloak_id) THEN
            RAISE EXCEPTION 'User % already exists in admin_invitations (lobby)', NEW.keycloak_id;
        END IF;
    END IF;

    -- When inserting into admin_invitations, check if the user is in app_users
    IF TG_TABLE_NAME = 'admin_invitations' AND TG_OP = 'INSERT' THEN
        IF EXISTS (SELECT 1 FROM app_users WHERE keycloak_id = NEW.keycloak_id) THEN
            RAISE EXCEPTION 'User % already exists in app_users', NEW.keycloak_id;
        END IF;
    END IF;

    -- On UPDATE, prevent changing keycloak_id
    IF TG_OP = 'UPDATE' AND NEW.keycloak_id != OLD.keycloak_id THEN
        RAISE EXCEPTION 'Cannot change keycloak_id % - it is immutable', OLD.keycloak_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach the trigger to both tables
CREATE OR REPLACE TRIGGER enforce_unique_keycloak_app_users
BEFORE INSERT OR UPDATE ON app_users
FOR EACH ROW EXECUTE FUNCTION check_user_keycloak_uniqueness();

CREATE OR REPLACE TRIGGER enforce_unique_keycloak_admin_invitations
BEFORE INSERT OR UPDATE ON admin_invitations
FOR EACH ROW EXECUTE FUNCTION check_user_keycloak_uniqueness();