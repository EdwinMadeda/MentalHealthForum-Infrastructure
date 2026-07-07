-- =====================================================================
-- PART 15: FUNCTIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 15.1 validate_category_depth - Prevent multi-level hierarchy
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validate_category_depth()
RETURNS TRIGGER AS $$
DECLARE
parent_parent UUID;
BEGIN
    IF NEW.parent_category_id IS NOT NULL THEN
SELECT parent_category_id INTO parent_parent
FROM forum_categories
WHERE id = NEW.parent_category_id;
IF parent_parent IS NOT NULL THEN
            RAISE EXCEPTION 'Only one level of category hierarchy allowed';
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.2 calculate_word_count - Auto-calculate word count
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_word_count()
RETURNS TRIGGER AS $$
BEGIN
    NEW.word_count := array_length(regexp_split_to_array(trim(NEW.content), '\s+'), 1);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.3 update_thread_on_post - Maintain thread activity
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_thread_on_post()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
UPDATE forum_threads
SET last_activity_at = NEW.created_at,
    post_count = post_count + 1
WHERE id = NEW.thread_id;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.4 validate_post_depth - Prevent nested replies
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validate_post_depth()
RETURNS TRIGGER AS $$
DECLARE
parent_parent UUID;
BEGIN
    IF NEW.parent_post_id IS NOT NULL THEN
SELECT parent_post_id INTO parent_parent
FROM forum_posts
WHERE id = NEW.parent_post_id;
IF parent_parent IS NOT NULL THEN
            RAISE EXCEPTION 'Only one level of replies allowed';
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.5 update_post_reaction_count - Maintain reaction count
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_post_reaction_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
UPDATE forum_posts SET reaction_count = reaction_count + 1 WHERE id = NEW.post_id;
ELSIF TG_OP = 'DELETE' THEN
UPDATE forum_posts SET reaction_count = reaction_count - 1 WHERE id = OLD.post_id;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.6 update_author_reputation - Award reputation for reactions
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_author_reputation()
RETURNS TRIGGER AS $$
DECLARE
points INTEGER;
    author UUID;
BEGIN
SELECT reputation_points INTO points FROM reaction_definitions WHERE reaction_type = NEW.reaction_type;
SELECT author_id INTO author FROM forum_posts WHERE id = NEW.post_id;
IF author IS NOT NULL THEN
UPDATE app_users SET reputation_score = reputation_score + points WHERE keycloak_id = author;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.7 update_last_modified - Auto-update timestamp
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_last_modified()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_modified_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.8 update_report_history - Audit log for reports
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_report_history()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO user_report_history (user_id, total_reports_made, last_report_at)
        VALUES (NEW.reporter_id, 1, NEW.reported_at)
        ON CONFLICT (user_id) DO UPDATE
                                            SET total_reports_made = user_report_history.total_reports_made + 1,
                                            last_report_at = NEW.reported_at;
INSERT INTO report_history (report_id, action, new_value, acted_by)
VALUES (NEW.id, 'CREATED', NEW.status::text, NEW.reporter_id);
END IF;

    IF TG_OP = 'UPDATE' THEN
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            INSERT INTO report_history (report_id, action, old_value, new_value, acted_by)
            VALUES (NEW.id, 'STATUS_CHANGED', OLD.status::text, NEW.status::text, NEW.reviewed_by);
            IF OLD.status = 'PENDING' AND NEW.status IN ('ACTION_TAKEN', 'DISMISSED') THEN
UPDATE user_report_history
SET reports_upheld = reports_upheld + CASE WHEN NEW.status = 'ACTION_TAKEN' THEN 1 ELSE 0 END,
    reports_dismissed = reports_dismissed + CASE WHEN NEW.status = 'DISMISSED' THEN 1 ELSE 0 END
WHERE user_id = NEW.reporter_id;
END IF;
END IF;
        IF OLD.assigned_moderator_id IS DISTINCT FROM NEW.assigned_moderator_id THEN
            INSERT INTO report_history (report_id, action, old_value, new_value, acted_by)
            VALUES (NEW.id, 'ASSIGNED', OLD.assigned_moderator_id::text, NEW.assigned_moderator_id::text, NEW.assigned_moderator_id);
END IF;
        IF OLD.severity IS DISTINCT FROM NEW.severity THEN
            INSERT INTO report_history (report_id, action, old_value, new_value, acted_by)
            VALUES (NEW.id, 'SEVERITY_CHANGED', OLD.severity::text, NEW.severity::text, NEW.reviewed_by);
END IF;
        IF OLD.action_taken IS DISTINCT FROM NEW.action_taken AND NEW.action_taken IS NOT NULL THEN
            INSERT INTO report_history (report_id, action, new_value, acted_by)
            VALUES (NEW.id, 'ACTION_TAKEN', NEW.action_taken::text, NEW.reviewed_by);
END IF;
END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.9 flag_content_on_report - Auto-flag reported content
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION flag_content_on_report()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.target_type = 'POST' AND NEW.post_id IS NOT NULL THEN
UPDATE forum_posts SET flagged_for_review = TRUE WHERE id = NEW.post_id;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.10 update_category_tags_updated_at - Auto-update timestamp
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_category_tags_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.11 update_moderation_action_templates_updated_at
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_moderation_action_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.12 update_report_templates_updated_at
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_report_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.13 update_dismissal_reason_templates_updated_at
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_dismissal_reason_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.14 update_updated_at_column (for user_connections)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.15 notify_on_reply - Create notifications for replies
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION notify_on_reply()
RETURNS TRIGGER AS $$
DECLARE
thread_creator_id UUID;
    parent_post_author_id UUID;
BEGIN
    IF NEW.parent_post_id IS NULL THEN
SELECT creator_id INTO thread_creator_id FROM forum_threads WHERE id = NEW.thread_id;
IF thread_creator_id IS NOT NULL AND thread_creator_id != NEW.author_id THEN
            INSERT INTO notifications (
                recipient_id, notification_type, title, message,
                action_url, related_user_id, related_post_id, related_thread_id
            )
SELECT
    thread_creator_id, 'REPLY', 'New reply to your thread',
    (SELECT display_name FROM app_users WHERE keycloak_id = NEW.author_id) || ' replied to your thread',
    '/threads/' || NEW.thread_id || '/posts/' || NEW.id,
    NEW.author_id, NEW.id, NEW.thread_id
    WHERE EXISTS (
                SELECT 1 FROM app_users
                WHERE keycloak_id = thread_creator_id
                  AND notification_preferences->'inApp'->>'replies' = 'true'
            );
END IF;
ELSE
SELECT author_id INTO parent_post_author_id FROM forum_posts WHERE id = NEW.parent_post_id;
IF parent_post_author_id IS NOT NULL AND parent_post_author_id != NEW.author_id THEN
            INSERT INTO notifications (
                recipient_id, notification_type, title, message,
                action_url, related_user_id, related_post_id, related_thread_id
            )
SELECT
    parent_post_author_id, 'REPLY', 'New reply to your post',
    (SELECT display_name FROM app_users WHERE keycloak_id = NEW.author_id) || ' replied to your post',
    '/threads/' || NEW.thread_id || '/posts/' || NEW.id,
    NEW.author_id, NEW.id, NEW.thread_id
    WHERE EXISTS (
                SELECT 1 FROM app_users
                WHERE keycloak_id = parent_post_author_id
                  AND notification_preferences->'inApp'->>'replies' = 'true'
            );
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.16 expire_restrictions - Expire user restrictions
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION expire_restrictions()
RETURNS void AS $$
BEGIN
UPDATE user_restrictions
SET is_active = FALSE
WHERE is_active = TRUE AND expires_at IS NOT NULL AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.17 expire_warnings - Expire user warnings
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION expire_warnings()
RETURNS void AS $$
BEGIN
UPDATE user_warnings
SET is_active = FALSE
WHERE is_active = TRUE AND expires_at IS NOT NULL AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.18 cleanup_expired_notifications - Delete expired notifications
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cleanup_expired_notifications()
RETURNS void AS $$
BEGIN
DELETE FROM notifications WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 15.19 unaccent_immutable - Wrapper for GIN trigram indexes
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.unaccent_immutable(text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
SELECT public.unaccent($1);
$$;

-- ---------------------------------------------------------------------
-- 15.20 fn_global_search - Full-text search across all content
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_global_search(
    p_search_query TEXT,
    p_sort_by TEXT DEFAULT 'relevance',
    p_viewer_id UUID DEFAULT NULL
)
RETURNS TABLE (
    entity_id UUID,
    entity_type TEXT,
    header VARCHAR,
    body_preview TEXT,
    search_score REAL,
    last_activity_at TIMESTAMP
) AS $$
DECLARE
v_tsquery tsquery;
BEGIN
    v_tsquery := websearch_to_tsquery('english', p_search_query);

RETURN QUERY
    WITH
    threads AS (
        SELECT
            t.id AS entity_id,
            'THREAD' AS entity_type,
            t.title AS header,
            LEFT(t.title, 200) AS body_preview,
            ts_rank(setweight(to_tsvector('english', COALESCE(t.title, '')), 'A'), v_tsquery) AS search_score,
            t.last_activity_at AS last_activity_at
        FROM forum_threads t
        WHERE t.is_deleted = FALSE
          AND setweight(to_tsvector('english', COALESCE(t.title, '')), 'A') @@ v_tsquery
    ),
    posts AS (
        SELECT
            p.id AS entity_id,
            'POST' AS entity_type,
            CASE WHEN p.is_anonymous THEN 'Anonymous Reply' ELSE COALESCE(u.display_name, 'Member') END AS header,
            LEFT(p.content, 200) AS body_preview,
            ts_rank(setweight(to_tsvector('english', COALESCE(p.content, '')), 'B'), v_tsquery) AS search_score,
            p.created_at AS last_activity_at
        FROM forum_posts p
        LEFT JOIN app_users u ON p.author_id = u.keycloak_id
        WHERE p.is_deleted = FALSE
          AND p.flagged_for_review = FALSE
          AND to_tsvector('english', COALESCE(p.content, '')) @@ v_tsquery
    ),
    categories AS (
        SELECT
            c.id AS entity_id,
            'CATEGORY' AS entity_type,
            c.name AS header,
            LEFT(c.description, 200) AS body_preview,
            ts_rank(setweight(to_tsvector('english', COALESCE(c.name, '')), 'A'), v_tsquery) AS search_score,
            c.created_at AS last_activity_at
        FROM forum_categories c
        WHERE c.is_active = TRUE
          AND to_tsvector('english', COALESCE(c.name, '')) @@ v_tsquery
    ),
    profiles AS (
        SELECT
            u.id AS entity_id,
            'PROFILE' AS entity_type,
            u.display_name AS header,
            LEFT(u.bio, 200) AS body_preview,
            ts_rank(setweight(to_tsvector('english', COALESCE(u.display_name, '')), 'A'), v_tsquery) AS search_score,
            u.last_active_at AS last_activity_at
        FROM app_users u
        WHERE u.is_active = TRUE
          AND u.account_deletion_requested_at IS NULL
          AND to_tsvector('english', COALESCE(u.display_name, '')) @@ v_tsquery
    ),
    combined AS (
        SELECT * FROM threads
        UNION ALL SELECT * FROM posts
        UNION ALL SELECT * FROM categories
        UNION ALL SELECT * FROM profiles
    )
SELECT
    c.entity_id,
    c.entity_type,
    c.header,
    c.body_preview,
    c.search_score,
    c.last_activity_at
FROM combined c
ORDER BY
    CASE WHEN p_sort_by = 'recent' THEN c.last_activity_at END DESC NULLS LAST,
    CASE WHEN p_sort_by = 'relevance' THEN c.search_score END DESC,
    c.header ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ---------------------------------------------------------------------
-- 15.21 category_is_visible -  Determine if a user can see a category based on
-- --                           participation_requirements.viewAccess.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION category_is_visible(
    p_category_id UUID,
    p_viewer_id UUID,
    p_is_admin BOOLEAN,
    p_is_moderator_or_admin BOOLEAN,
    p_is_verified BOOLEAN
)
    RETURNS BOOLEAN AS $$
DECLARE
v_exists BOOLEAN;
    v_visible BOOLEAN;
BEGIN

    -- Check if category actually exits
    -- Non-existent categories are Never visible to anyone
SELECT EXISTS(SELECT 1 FROM forum_categories WHERE id = p_category_id) INTO v_exists;
IF NOT v_exists THEN
        RETURN FALSE;
END IF;

    -- Admin bypass: admins see any category (active or inactive)
    IF p_is_admin = TRUE THEN
        RETURN TRUE;
END IF;

    -- Recursive CTE to check all ancestors (including self) for non-admins
WITH RECURSIVE category_ancestors AS (
    -- Base case: start with the given category
    SELECT
        id,
        is_active,
        COALESCE(participation_requirements ->> 'viewAccess', 'MEMBERS_ONLY') AS view_access,
        parent_category_id
    FROM forum_categories
    WHERE id = p_category_id

    UNION ALL

    -- Recursive case: climb up to the parent
    SELECT
        c.id,
        c.is_active,
        COALESCE(c.participation_requirements ->> 'viewAccess', 'MEMBERS_ONLY') AS view_access,
        c.parent_category_id
    FROM forum_categories c
             INNER JOIN category_ancestors a ON c.id = a.parent_category_id
)
-- Check if ALL ancestors (including self) are visible
SELECT bool_and(
               is_active = TRUE
                   AND (
                   view_access = 'PUBLIC'
                       OR (view_access = 'MEMBERS_ONLY' AND p_viewer_id IS NOT NULL)
                       OR (view_access = 'VERIFIED_ONLY' AND p_is_verified = TRUE)
                       OR (view_access = 'MODERATORS_ONLY' AND p_is_moderator_or_admin = TRUE)
                       OR (view_access = 'ADMINS_ONLY' AND p_is_admin = TRUE)
                   )
       )
INTO v_visible
FROM category_ancestors;

-- If no rows found (category doesn't exist), return FALSE
RETURN COALESCE(v_visible, FALSE);
END;
$$ LANGUAGE plpgsql STABLE;


-- ---------------------------------------------------------------------
-- 15.22 profile_is_visible -  Determine if a user can see another's profile based on
-- --                           profile visibility, roles, groups (must be active).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION profile_is_visible(
    p_target_user_id UUID,
    p_viewer_id UUID,
    p_is_admin BOOLEAN,
    p_is_moderator_or_admin BOOLEAN
)
RETURNS BOOLEAN AS $$
DECLARE
v_visibility TEXT;
    v_target_roles TEXT[];
    v_target_groups TEXT[];
BEGIN
    -- Admin/Moderator bypass (they see everything) (BELT 1)
    IF p_is_admin = TRUE OR p_is_moderator_or_admin = TRUE THEN
        RETURN TRUE;
END IF;

    -- Self always visible
    IF p_target_user_id = p_viewer_id THEN
        RETURN TRUE;
END IF;

    -- Fetch the target user's profile visibility, roles, groups (must be active)
SELECT
    profile_visibility,
    roles,
    groups
INTO
    v_visibility,
    v_target_roles,
    v_target_groups
FROM app_users
WHERE keycloak_id = p_target_user_id
  AND is_active = TRUE
  AND account_deletion_requested_at IS NULL;

-- If target user doesn't exist or is inactive/deleted
IF NOT FOUND THEN
        RETURN FALSE;
END IF;

    -- If target is Admin/moderator visible to everyone (BELT 2 / SUSPENDERS - global override)
    IF (v_target_roles && ARRAY['admin', 'moderator'])
        OR (v_target_groups && ARRAY['/administrators', '/moderators/professional', '/moderators/peer']) THEN
        RETURN TRUE;
END IF;


    -- Apply visibility rules (with COALESCE to guarantee FALSE on any NULL ambiguity)
RETURN COALESCE(
        (
            (v_visibility = 'MEMBERS_ONLY' AND p_viewer_id IS NOT NULL)
                OR (v_visibility = 'CONNECTED_ONLY' AND p_viewer_id IS NOT NULL AND EXISTS (
                SELECT 1
                FROM user_connections uc
                WHERE uc.status = 'ACCEPTED'
                  AND (
                    (uc.user_1 = p_viewer_id AND uc.user_2 = p_target_user_id)
                        OR (uc.user_1 = p_target_user_id AND uc.user_2 = p_viewer_id)
                    ))
                )
                OR (v_visibility = 'PRIVATE' AND (
                -- Self already caught above, but keeping for completeness
                p_target_user_id = p_viewer_id
                    OR p_is_admin = TRUE
                    OR p_is_moderator_or_admin = TRUE
                    OR (v_target_roles && ARRAY['admin', 'moderator'])
                    OR (v_target_groups && ARRAY['/administrators', '/moderators/professional', '/moderators/peer'])
                    OR EXISTS (
                    SELECT 1
                    FROM user_connections uc
                    WHERE uc.status = 'ACCEPTED'
                      AND (
                        (uc.user_1 = p_viewer_id AND uc.user_2 = p_target_user_id)
                            OR (uc.user_1 = p_target_user_id AND uc.user_2 = p_viewer_id)
                        ))
                )
                )
            )
    , FALSE);
END;
$$ LANGUAGE plpgsql STABLE;