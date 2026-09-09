-- =====================================================================
-- PART 14: INDEXES (including CONCURRENTLY where needed)
-- =====================================================================

-- ---------------------------------------------------------------------
-- app_users indexes
-- ---------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_keycloak_id ON app_users (keycloak_id);
CREATE INDEX IF NOT EXISTS idx_app_users_display_name ON app_users (display_name);
CREATE INDEX IF NOT EXISTS idx_app_users_display_name_sort ON app_users (COALESCE(NULLIF(display_name, ''), 'zzzzzzzz'));
CREATE INDEX IF NOT EXISTS idx_app_users_date_joined ON app_users (date_joined DESC);
CREATE INDEX IF NOT EXISTS idx_app_users_posts_count ON app_users (posts_count DESC);
CREATE INDEX IF NOT EXISTS idx_app_users_reputation ON app_users (reputation_score DESC);

-- Recreate indexes using account_status instead of is_active
CREATE INDEX idx_active_users ON app_users (last_active_at) WHERE account_status = 'ACTIVE';
CREATE INDEX idx_app_users_last_active ON app_users (last_active_at) WHERE account_status = 'ACTIVE';
CREATE INDEX idx_app_users_last_login ON app_users (last_login_at) WHERE account_status = 'ACTIVE';
CREATE INDEX idx_app_users_account_status ON app_users (account_status, last_active_at DESC);

-- Additional index for scheduled deletion job
CREATE INDEX idx_app_users_deletion_scheduled ON app_users (deletion_scheduled_at) WHERE account_status = 'PENDING_DELETION';

CREATE INDEX IF NOT EXISTS idx_app_users_roles ON app_users USING gin (roles);
CREATE INDEX IF NOT EXISTS idx_app_users_groups ON app_users USING gin (groups);

-- Trigram index for display_name (CONCURRENTLY for production safety)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_app_users_display_name_trgm ON app_users
    USING GIN (public.unaccent_immutable(display_name) gin_trgm_ops);

-- Full-text search index for user profiles (simple_unaccent for names/bio)
CREATE INDEX IF NOT EXISTS idx_app_users_search ON app_users
    USING gin (
    (to_tsvector('public.simple_unaccent', COALESCE(display_name, '')) ||
    to_tsvector('public.simple_unaccent', COALESCE(bio, '')))
    );

-- This ensures only ONE row can ever have is_super_admin = TRUE
CREATE UNIQUE INDEX idx_unique_super_admin ON app_users (is_super_admin) WHERE is_super_admin = TRUE;

-- ---------------------------------------------------------------------
-- admin_invitations indexes
-- ---------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_invitations_keycloak_id ON admin_invitations (keycloak_id);
CREATE INDEX IF NOT EXISTS idx_admin_invitations_date_created ON admin_invitations (date_created DESC);
CREATE INDEX IF NOT EXISTS idx_admin_invitations_email_search ON admin_invitations (LOWER(email));

-- ---------------------------------------------------------------------
-- verification_tokens indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_tokens_email_type ON verification_tokens (email, type);
CREATE INDEX IF NOT EXISTS idx_tokens_lookup ON verification_tokens (token, email);

-- ---------------------------------------------------------------------
-- otp_credentials indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_otp_email_purpose ON otp_credentials (email, purpose);
CREATE INDEX IF NOT EXISTS idx_otp_expiry ON otp_credentials (expiry_date);

-- ---------------------------------------------------------------------
-- forum_categories indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_category_active_sort ON forum_categories (is_active DESC, sort_order ASC);
CREATE INDEX IF NOT EXISTS idx_category_slug ON forum_categories (slug);
CREATE INDEX IF NOT EXISTS idx_category_parent_id ON forum_categories (parent_category_id);
CREATE INDEX IF NOT EXISTS idx_forum_categories_search ON forum_categories
    USING gin ((to_tsvector('public.english_unaccent', COALESCE(name, '')) ||
    to_tsvector('public.english_unaccent', COALESCE(description, '')))
    );

-- ---------------------------------------------------------------------
-- user_audit_reason_definitions indexes
-- ---------------------------------------------------------------------
CREATE INDEX idx_user_audit_reason_definitions_action_type ON user_audit_reason_definitions(action_type);
CREATE INDEX idx_user_audit_reason_definitions_active ON user_audit_reason_definitions(is_active);

-- ---------------------------------------------------------------------
-- category_tags indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_category_tags_name ON category_tags (name);
CREATE INDEX IF NOT EXISTS idx_category_tags_slug ON category_tags (slug);
CREATE INDEX IF NOT EXISTS idx_category_tags_created_by ON category_tags (created_by);

-- ---------------------------------------------------------------------
-- category_tag_assignments indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_category_tag_assignments_category ON category_tag_assignments (category_id);
CREATE INDEX IF NOT EXISTS idx_category_tag_assignments_tag ON category_tag_assignments (tag_id);
CREATE INDEX IF NOT EXISTS idx_category_tag_assignments_assigned_by ON category_tag_assignments (assigned_by);

-- ---------------------------------------------------------------------
-- forum_threads indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_thread_activity ON forum_threads (category_id ASC, is_sticky DESC, last_activity_at DESC);
CREATE INDEX IF NOT EXISTS idx_thread_status ON forum_threads (thread_status ASC, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_thread_type ON forum_threads (thread_type);
CREATE INDEX IF NOT EXISTS idx_thread_featured ON forum_threads (is_featured DESC, created_at DESC) WHERE (is_featured = TRUE);
CREATE INDEX IF NOT EXISTS idx_thread_creator ON forum_threads (creator_id ASC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_forum_threads_search ON forum_threads
    USING gin (to_tsvector('public.english_unaccent', COALESCE(title, '')));

-- Trigram index for thread title (CONCURRENTLY)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_threads_title_trgm ON forum_threads
    USING GIN (public.unaccent_immutable(title) gin_trgm_ops);

-- ---------------------------------------------------------------------
-- thread_edit_history indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_thread_edit_history_thread ON thread_edit_history (thread_id, edited_at DESC);
CREATE INDEX IF NOT EXISTS idx_thread_edit_history_editor ON thread_edit_history (edited_by);

-- ---------------------------------------------------------------------
-- forum_posts indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_posts_by_thread ON forum_posts (thread_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_posts_by_author ON forum_posts (author_id ASC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_flagged ON forum_posts (flagged_for_review ASC, created_at DESC) WHERE (flagged_for_review = TRUE);
CREATE INDEX IF NOT EXISTS idx_posts_parent ON forum_posts (parent_post_id) WHERE (parent_post_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_posts_type ON forum_posts (post_type, thread_id);
CREATE INDEX IF NOT EXISTS idx_forum_posts_search ON forum_posts
    USING gin (to_tsvector('public.english_unaccent', COALESCE(content, '')));

-- Trigram index for post content (CONCURRENTLY)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_forum_posts_content_trgm ON forum_posts
    USING GIN (public.unaccent_immutable(content) gin_trgm_ops);

-- ---------------------------------------------------------------------
-- post_edit_history indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_edit_history_post ON post_edit_history (post_id, edited_at DESC);
CREATE INDEX IF NOT EXISTS idx_edit_history_user ON post_edit_history (edited_by);

-- ---------------------------------------------------------------------
-- post_reactions indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_reaction_post ON post_reactions (post_id, reaction_type);
CREATE INDEX IF NOT EXISTS idx_reaction_user ON post_reactions (user_id ASC, created_at DESC);

-- ---------------------------------------------------------------------
-- content_reports indexes
-- ---------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_active_thread_report ON content_reports (reporter_id, thread_id)
    WHERE status IN ('PENDING', 'UNDER_REVIEW') AND thread_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_active_post_report ON content_reports (reporter_id, post_id)
    WHERE status IN ('PENDING', 'UNDER_REVIEW') AND post_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_active_user_report ON content_reports (reporter_id, reported_user_id)
    WHERE status IN ('PENDING', 'UNDER_REVIEW') AND reported_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reports_pending ON content_reports (status ASC, severity DESC, reported_at DESC) WHERE (status = 'PENDING');
CREATE INDEX IF NOT EXISTS idx_reports_assigned ON content_reports (assigned_moderator_id, status) WHERE (assigned_moderator_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON content_reports (reporter_id ASC, reported_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_post ON content_reports (post_id) WHERE (post_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_reports_thread ON content_reports (thread_id) WHERE (thread_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_user_report_history ON content_reports (reporter_id, reported_at DESC);

-- ---------------------------------------------------------------------
-- report_history indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_report_history_report ON report_history (report_id, created_at DESC);

-- ---------------------------------------------------------------------
-- report_templates indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_templates_category ON report_templates (report_category, display_order);
CREATE INDEX IF NOT EXISTS idx_report_templates_reason_code ON report_templates (reason_code);
CREATE INDEX IF NOT EXISTS idx_report_templates_active_order ON report_templates (is_active, display_order);

-- ---------------------------------------------------------------------
-- moderation templates indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_mod_action_templates_active ON moderation_action_templates (is_active, display_order);
CREATE INDEX IF NOT EXISTS idx_dismissal_templates_active ON dismissal_reason_templates (is_active, display_order);

-- ---------------------------------------------------------------------
-- moderation_queue indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_queue_active ON moderation_queue (cleared_at) WHERE cleared_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_queue_target ON moderation_queue (target_type, target_id);

-- ---------------------------------------------------------------------
-- moderation_log indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_moderator_actions ON moderation_log (moderator_id, action_taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_history ON moderation_log (target_user_id, action_taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_action_type ON moderation_log (action_type, action_taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_report_actions ON moderation_log (report_id) WHERE report_id IS NOT NULL;

-- ---------------------------------------------------------------------
-- moderation_rules indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_rules_active ON moderation_rules (is_active, priority DESC) WHERE is_active = TRUE;

-- ---------------------------------------------------------------------
-- user_warnings indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_warnings_user ON user_warnings (user_id, warned_at DESC);
CREATE INDEX IF NOT EXISTS idx_warnings_active ON user_warnings (user_id, is_active) WHERE is_active = TRUE;

-- ---------------------------------------------------------------------
-- user_restrictions indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_restrictions_user ON user_restrictions (user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_restrictions_active ON user_restrictions (expires_at) WHERE is_active = TRUE AND expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_restrictions_type ON user_restrictions (restriction_type, is_active);

-- ---------------------------------------------------------------------
-- thread_bookmarks indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON thread_bookmarks (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookmarks_thread ON thread_bookmarks (thread_id);

-- ---------------------------------------------------------------------
-- user_connections indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_pending_incoming ON user_connections (user_1, user_2) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_connections_active ON user_connections (user_1, user_2) WHERE status = 'ACCEPTED';
CREATE INDEX IF NOT EXISTS idx_connections_initiated ON user_connections (initiated_by) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_user_connections_lookup ON user_connections (user_1, user_2);
CREATE INDEX IF NOT EXISTS idx_connections_updated ON user_connections (updated_at);

-- ---------------------------------------------------------------------
-- focus_categories indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_focus_user ON focus_categories (user_id);

-- ---------------------------------------------------------------------
-- watch_threads indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_watches_user ON watch_threads (user_id);

-- ---------------------------------------------------------------------
-- notifications indexes
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications (recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications (recipient_id, is_read, created_at DESC) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications (notification_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_expiry ON notifications (expires_at);