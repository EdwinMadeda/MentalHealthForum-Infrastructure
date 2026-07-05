-- =====================================================================
-- PART 17: VIEWS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 17.1 trending_threads - Trending threads based on engagement
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW trending_threads AS
SELECT
    ft.id,
    ft.title,
    ft.category_id,
    ft.creator_id,
    ft.view_count,
    ft.post_count,
    ft.created_at,
    ft.last_activity_at,
    (ft.post_count * 2 + ft.view_count / 10 + CASE
                                                  WHEN ft.last_activity_at > NOW() - INTERVAL '1 day' THEN 50
        WHEN ft.last_activity_at > NOW() - INTERVAL '3 days' THEN 20
        ELSE 0
        END) AS trending_score
FROM forum_threads ft
WHERE ft.is_deleted = FALSE
  AND ft.thread_status = 'OPEN'
  AND ft.last_activity_at > NOW() - INTERVAL '7 days'
ORDER BY trending_score DESC
    LIMIT 50;

-- ---------------------------------------------------------------------
-- 17.2 user_category_activity - Activity per category per user
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW user_category_activity AS
SELECT
    fp.author_id AS user_id,
    ft.category_id,
    fc.name AS category_name,
    COUNT(DISTINCT fp.id) AS post_count,
    COUNT(DISTINCT ft.id) AS thread_count,
    MAX(fp.created_at) AS last_active_in_category_at,
    MIN(fp.created_at) AS first_active_in_category_at
FROM forum_posts fp
         JOIN forum_threads ft ON fp.thread_id = ft.id
         JOIN forum_categories fc ON ft.category_id = fc.id
WHERE fp.is_deleted = FALSE
  AND ft.is_deleted = FALSE
  AND fp.author_id IS NOT NULL
GROUP BY fp.author_id, ft.category_id, fc.name;

-- ---------------------------------------------------------------------
-- 17.3 user_active_restrictions - Active restrictions per user
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW user_active_restrictions AS
SELECT
    user_id,
    array_agg(restriction_type) AS active_restriction_types,
    MAX(expires_at) AS latest_expiry
FROM user_restrictions
WHERE is_active = TRUE
  AND (expires_at IS NULL OR expires_at > NOW())
GROUP BY user_id;

-- ---------------------------------------------------------------------
-- 17.4 user_warning_counts - Active warnings per user
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW user_warning_counts AS
SELECT
    user_id,
    COUNT(*) FILTER (WHERE warning_type = 'INFORMAL') AS informal_warnings,
    COUNT(*) FILTER (WHERE warning_type = 'FORMAL') AS formal_warnings,
    COUNT(*) FILTER (WHERE warning_type = 'FINAL') AS final_warnings,
    COUNT(*) AS total_active_warnings
FROM user_warnings
WHERE is_active = TRUE
  AND (expires_at IS NULL OR expires_at > NOW())
GROUP BY user_id;

-- ---------------------------------------------------------------------
-- 17.5 user_connection_counts - Connection statistics per user
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW user_connection_counts AS
SELECT
    u.keycloak_id AS user_id,
    (SELECT COUNT(*) FROM user_connections WHERE (user_1 = u.keycloak_id OR user_2 = u.keycloak_id) AND status = 'ACCEPTED') AS connection_count,
    (SELECT COUNT(*) FROM user_connections WHERE user_1 = u.keycloak_id AND status = 'ACCEPTED') AS connections_initiated_count,
    (SELECT COUNT(*) FROM user_connections WHERE user_2 = u.keycloak_id AND status = 'ACCEPTED') AS connections_received_count
FROM app_users u;