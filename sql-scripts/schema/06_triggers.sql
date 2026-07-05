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