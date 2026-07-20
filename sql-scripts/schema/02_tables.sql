-- =====================================================================
-- PART 3: USER PROFILE & IDENTITY TABLES
-- =====================================================================

-- ---------------------------------------------------------------------
-- 3.1 app_users - Main user profile table
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app_users (
    id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    keycloak_id                   UUID NOT NULL,
    email                         VARCHAR(255) NOT NULL,
    username                      VARCHAR(255) NOT NULL,
    first_name                    VARCHAR(255) NOT NULL,
    last_name                     VARCHAR(255) NOT NULL,
    roles                         TEXT[],
    groups                        TEXT[],
    is_enabled                    BOOLEAN,
    last_synced_at                TIMESTAMP WITH TIME ZONE,
    date_joined                   TIMESTAMP WITH TIME ZONE NOT NULL,
    display_name                  VARCHAR(100),
    avatar_url                    TEXT,
    bio                           TEXT,
    timezone                      VARCHAR(50) DEFAULT 'UTC',
    language                      VARCHAR(10) DEFAULT 'en',
    profile_visibility            profile_visibility_enum DEFAULT 'MEMBERS_ONLY',
    support_role                  support_role_enum DEFAULT 'NOT_SPECIFIED',
    notification_preferences      JSONB DEFAULT '{
                                           "inApp": {
                                             "replies": true,
                                             "reactions": true,
                                             "follows": true,
                                             "moderation": true,
                                             "system": true
                                           },
                                           "email": {
                                             "replies": false,
                                             "reactions": false,
                                             "follows": false,
                                             "moderation": true,
                                             "system": false
                                           }
                                         }'::jsonb,
    posts_count                   INTEGER DEFAULT 0,
    reputation_score              NUMERIC(10,2) DEFAULT 0.0,
    last_active_at                TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    last_active_updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    last_posted_at                TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    last_login_at                 TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    is_super_admin                BOOLEAN DEFAULT FALSE,
    account_status                account_status NOT NULL DEFAULT 'ACTIVE',
    deletion_requested_at         TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    deletion_scheduled_at         TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    purged_at                     TIMESTAMP WITH TIME ZONE DEFAULT NULL
);

COMMENT ON TABLE app_users IS 'Main user profile table - syncs with Keycloak';
COMMENT ON COLUMN app_users.keycloak_id IS 'The unique Keycloak UUID (sub claim)';
COMMENT ON COLUMN app_users.notification_preferences IS 'JSONB storing notification preferences for email and in-app';

-- ---------------------------------------------------------------------
-- 3.2 admin_invitations - Admin/invited user staging
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_invitations (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    keycloak_id       UUID NOT NULL,
    email             VARCHAR(255) NOT NULL,
    username          VARCHAR(255) NOT NULL,
    first_name        VARCHAR(255) NOT NULL,
    last_name         VARCHAR(255) NOT NULL,
    groups            TEXT[],
    is_enabled        BOOLEAN,
    is_email_verified BOOLEAN,
    date_created      TIMESTAMP WITH TIME ZONE NOT NULL,
                                    invited_by        UUID NOT NULL REFERENCES app_users(keycloak_id),
    updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                    current_stage     onboarding_stage_enum DEFAULT 'AWAITING_VERIFICATION',
                                    is_initial_login  BOOLEAN NOT NULL DEFAULT TRUE
                                    );

-- ---------------------------------------------------------------------
-- 3.3 pending_users - Self-registration staging
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pending_users (
    id                 BIGSERIAL PRIMARY KEY,
    username           VARCHAR(255) NOT NULL UNIQUE,
    email              VARCHAR(255) NOT NULL UNIQUE,
    encrypted_password TEXT NOT NULL,
    first_name         VARCHAR(100) NOT NULL,
    last_name          VARCHAR(100) NOT NULL,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                                     );

-- ---------------------------------------------------------------------
-- 3.4 verification_tokens - Email verification tokens
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS verification_tokens (
    id          BIGSERIAL PRIMARY KEY,
    token       VARCHAR(255) NOT NULL UNIQUE,
    email       VARCHAR(255) NOT NULL,
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    type        VARCHAR(50) NOT NULL,
    group_path  TEXT,
    new_value   VARCHAR(255),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- 3.5 otp_credentials - One-time password storage
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS otp_credentials (
    id          BIGSERIAL PRIMARY KEY,
    email       VARCHAR(255) NOT NULL,
    code_hash   VARCHAR(255) NOT NULL,
    purpose     otp_purpose_enum NOT NULL,
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                              );

-- =====================================================================
-- PART 4: FORUM STRUCTURE
-- =====================================================================

-- ---------------------------------------------------------------------
-- 4.1 forum_categories - Main category hierarchy
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS forum_categories (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                        VARCHAR(100) NOT NULL UNIQUE,
    slug                        VARCHAR(100) NOT NULL UNIQUE,
    description                 TEXT,
    color_theme                 VARCHAR(50),
    parent_category_id          UUID REFERENCES forum_categories(id) ON DELETE CASCADE,
    participation_requirements  JSONB DEFAULT '{}'::jsonb,
    content_warning_type        content_warning_enum DEFAULT 'NONE',
    content_warning_custom_text VARCHAR(255) DEFAULT NULL,
    default_thread_settings     JSONB DEFAULT '{}'::jsonb,
    is_active                   BOOLEAN DEFAULT TRUE NOT NULL,
    sort_order                  INTEGER DEFAULT 0 NOT NULL,
    created_at                  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_no_self_parent CHECK (id <> parent_category_id)
);

-- ---------------------------------------------------------------------
-- 4.2 category_tags - Central tag library
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS category_tags (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(50) NOT NULL UNIQUE,
    slug        VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_by  UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ---------------------------------------------------------------------
-- 4.3 category_tag_assignments - Category to tag mapping
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS category_tag_assignments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES forum_categories(id) ON DELETE CASCADE,
    tag_id      UUID NOT NULL REFERENCES category_tags(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (category_id, tag_id)
);

-- ---------------------------------------------------------------------
-- 4.4 thread_type_definitions - Reference data for thread types
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS thread_type_definitions (
    thread_type  thread_type_enum PRIMARY KEY,
    display_name VARCHAR(50) NOT NULL,
    description  TEXT NOT NULL,
    icon_hint    VARCHAR(50),
    example      TEXT
    );

-- ---------------------------------------------------------------------
-- 4.5 thread_status_definitions - Reference data for thread status
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS thread_status_definitions (
    thread_status thread_status_enum PRIMARY KEY,
    display_name  VARCHAR(50) NOT NULL,
    description   TEXT NOT NULL,
    user_visible  BOOLEAN NOT NULL
    );

-- =====================================================================
-- PART 5: THREADS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 5.1 forum_threads - Main thread table
-- Note: best_answer_post_id FK added in PART 3 (circular dependency)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS forum_threads (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title                       VARCHAR(255) NOT NULL,
    creator_id                  UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    category_id                 UUID NOT NULL REFERENCES forum_categories(id) ON DELETE RESTRICT,
    thread_type                 thread_type_enum NOT NULL DEFAULT 'DISCUSSION',
    thread_status               thread_status_enum NOT NULL DEFAULT 'OPEN',
    resolved_at                 TIMESTAMP WITH TIME ZONE,
    resolved_by_user_id         UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    best_answer_post_id         UUID,
    content_warning_type        content_warning_enum NOT NULL DEFAULT 'NONE',
    content_warning_custom_text VARCHAR(255) DEFAULT NULL,
    tags                        TEXT[],
    is_sticky                   BOOLEAN DEFAULT FALSE NOT NULL,
    is_featured                 BOOLEAN DEFAULT FALSE NOT NULL,
    is_deleted                  BOOLEAN DEFAULT FALSE NOT NULL,
    thread_settings             JSONB DEFAULT '{}'::jsonb,
    lock_reason                 TEXT,
    locked_by                   UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    locked_at                   TIMESTAMP WITH TIME ZONE,
    lock_expires_at             TIMESTAMP WITH TIME ZONE,
    created_at                  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at                  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_activity_at            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    post_count                  INTEGER DEFAULT 0 NOT NULL,
    view_count                  INTEGER DEFAULT 0 NOT NULL,
    CONSTRAINT chk_resolved_only_for_questions CHECK (
        (thread_status != 'RESOLVED') OR (thread_type = 'QUESTION')
    )
);

COMMENT ON COLUMN forum_threads.thread_settings IS 'JSONB: auto_lock_at, scheduled_post_at, custom_reminder, etc.';
COMMENT ON COLUMN forum_threads.lock_reason IS 'Reason provided by moderator when locking the thread';
COMMENT ON COLUMN forum_threads.lock_expires_at IS 'When the lock expires (NULL = permanent lock)';

-- ---------------------------------------------------------------------
-- 5.2 thread_edit_history - Thread edit audit trail
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS thread_edit_history (
    id                                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id                            UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
    previous_title                       VARCHAR(255),
    previous_tags                        TEXT[],
    previous_content_warning_type        content_warning_enum,
    previous_content_warning_custom_text VARCHAR(255),
    edited_at                            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    edited_by                            UUID REFERENCES app_users(keycloak_id),
    edit_reason_type                     edit_reason_enum,
    edit_reason_custom_text              VARCHAR(255),
    is_moderator_edit                    BOOLEAN DEFAULT FALSE NOT NULL
);

COMMENT ON TABLE thread_edit_history IS 'Tracks all edits made to threads (title, tags, content warnings)';

-- =====================================================================
-- PART 6: POSTS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 6.1 forum_posts - Main post table
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS forum_posts (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id                   UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
    author_id                   UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    post_type                   post_type_enum NOT NULL DEFAULT 'REPLY',
    parent_post_id              UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
    content                     TEXT NOT NULL,
    word_count                  INTEGER DEFAULT 0 NOT NULL,
    content_warning_type        content_warning_enum DEFAULT 'NONE',
    content_warning_custom_text VARCHAR(255) DEFAULT NULL,
    flagged_for_review          BOOLEAN DEFAULT FALSE NOT NULL,
    is_edited                   BOOLEAN DEFAULT FALSE NOT NULL,
    edit_reason_type            edit_reason_enum,
    edit_reason_custom_text     VARCHAR(255) DEFAULT NULL,
    edited_by_user_id           UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    is_anonymous                BOOLEAN DEFAULT FALSE NOT NULL,
    anonymous_identifier        VARCHAR(50) DEFAULT NULL,
    created_at                  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at                  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_deleted                  BOOLEAN DEFAULT FALSE NOT NULL,
    reaction_count              INTEGER DEFAULT 0 NOT NULL,
    CONSTRAINT uq_post_thread UNIQUE (id, thread_id)
);

COMMENT ON COLUMN forum_posts.anonymous_identifier IS 'Consistent pseudonym within thread for anonymous posts';

-- ---------------------------------------------------------------------
-- 6.2 post_edit_history - Post edit audit trail
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS post_edit_history (
    id                                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id                              UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
    previous_content                     TEXT NOT NULL,
    previous_word_count                  INTEGER,
    previous_content_warning_type        content_warning_enum,
    previous_content_warning_custom_text VARCHAR(255),
    edited_at                            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    edited_by                            UUID NOT NULL REFERENCES app_users(keycloak_id),
    edit_reason_type                     edit_reason_enum,
    edit_reason_custom_text              VARCHAR(255),
    is_moderator_edit                    BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE post_edit_history IS 'Tracks all edits to post content';

-- =====================================================================
-- PART 7: REACTIONS & ENGAGEMENT
-- =====================================================================

-- ---------------------------------------------------------------------
-- 7.1 reaction_definitions - Reference data for reactions
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reaction_definitions (
    reaction_type      reaction_enum PRIMARY KEY,
    display_name       VARCHAR(50) NOT NULL,
    icon_class         VARCHAR(50),
    description        TEXT NOT NULL,
    reputation_points  INTEGER DEFAULT 0 NOT NULL,
    available_to_roles TEXT[],
    sort_order         INTEGER DEFAULT 0 NOT NULL,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE reaction_definitions IS 'All available reaction types with metadata and reputation points';

-- ---------------------------------------------------------------------
-- 7.2 post_reactions - User reactions to posts
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS post_reactions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id       UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
    user_id       UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    reaction_type reaction_enum NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_user_post_reaction UNIQUE (post_id, user_id, reaction_type)
);

-- =====================================================================
-- PART 8: CONTENT REPORTS & MODERATION
-- =====================================================================

-- ---------------------------------------------------------------------
-- 8.1 report_templates - Pre-defined report reasons
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS report_templates (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_category  report_category_enum NOT NULL,
    template_text    TEXT NOT NULL,
    requires_details BOOLEAN DEFAULT FALSE NOT NULL,
    auto_severity    severity_enum NOT NULL,
    display_order    INTEGER DEFAULT 0 NOT NULL,
    is_active        BOOLEAN DEFAULT TRUE NOT NULL,
    reason_code      report_reason_code_enum,
    example_details  TEXT,
    created_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- 8.2 content_reports - Main report tracking
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS content_reports (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id           UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    is_anonymous          BOOLEAN DEFAULT FALSE NOT NULL,
    target_type           report_target_type_enum NOT NULL,
    thread_id             UUID REFERENCES forum_threads(id) ON DELETE CASCADE,
    post_id               UUID REFERENCES forum_posts(id) ON DELETE CASCADE,
    reported_user_id      UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    report_category       report_category_enum NOT NULL,
    severity              severity_enum NOT NULL,
    reason                VARCHAR(100) NOT NULL,
    details               TEXT,
    status                report_status_enum DEFAULT 'PENDING' NOT NULL,
    assigned_moderator_id UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    assigned_at           TIMESTAMP WITH TIME ZONE,
    reviewed_at           TIMESTAMP WITH TIME ZONE,
    reviewed_by           UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    action_taken          moderation_action_enum,
    action_taken_details  TEXT,
    resolution_notes      TEXT,
    dismissal_reason      dismissal_reason_enum,
    auto_flagged          BOOLEAN DEFAULT FALSE NOT NULL,
    related_report_ids    UUID[],
    appeal_id             UUID,
    post_content          TEXT,
    reported_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_modified_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    -- All constraints remain the same
    CONSTRAINT chk_report_target CHECK (
        (target_type = 'POST' AND post_id IS NOT NULL) OR
        (target_type = 'THREAD' AND thread_id IS NOT NULL) OR
        (target_type = 'USER' AND reported_user_id IS NOT NULL)
    ),
    CONSTRAINT chk_dismissal_reason_required CHECK (
        (status != 'DISMISSED') OR
        (status = 'DISMISSED' AND dismissal_reason IS NOT NULL)
    ),
    CONSTRAINT chk_thread_id_required_for_thread_reports CHECK (
        (target_type != 'THREAD') OR (target_type = 'THREAD' AND thread_id IS NOT NULL)
    ),
    CONSTRAINT chk_post_id_required_for_post_reports CHECK (
        (target_type != 'POST') OR (target_type = 'POST' AND post_id IS NOT NULL)
    ),
    CONSTRAINT chk_post_content_required_for_post_reports CHECK (
        (target_type != 'POST') OR (target_type = 'POST' AND post_content IS NOT NULL)
    ),
    CONSTRAINT chk_reported_user_id_required_for_user_reports CHECK (
        (target_type != 'USER') OR (target_type = 'USER' AND reported_user_id IS NOT NULL)
    ),
    CONSTRAINT chk_reported_user_id_null_for_thread_reports CHECK (
        (target_type != 'THREAD') OR (target_type = 'THREAD' AND reported_user_id IS NULL)
    ),
    CONSTRAINT chk_post_id_null_for_thread_reports CHECK (
        (target_type != 'THREAD') OR (target_type = 'THREAD' AND post_id IS NULL)
    ),
    CONSTRAINT chk_thread_id_null_for_user_reports CHECK (
        (target_type != 'USER') OR (target_type = 'USER' AND thread_id IS NULL)
    ),
    CONSTRAINT chk_post_id_null_for_user_reports CHECK (
        (target_type != 'USER') OR (target_type = 'USER' AND post_id IS NULL)
    )
);

COMMENT ON COLUMN content_reports.action_taken IS 'Moderation action taken (enum from moderation_action_enum)';
COMMENT ON COLUMN content_reports.dismissal_reason IS 'Reason code for dismissal (when status = DISMISSED)';
COMMENT ON COLUMN content_reports.post_content IS 'Snapshot of the reported post content at the time of reporting';

-- ---------------------------------------------------------------------
-- 8.3 report_history - Report audit log
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS report_history (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id  UUID NOT NULL REFERENCES content_reports(id) ON DELETE CASCADE,
    action     TEXT NOT NULL,
    old_value  TEXT,
    new_value  TEXT,
    acted_by   UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ---------------------------------------------------------------------
-- 8.4 user_report_history - Reporter statistics
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_report_history (
    user_id            UUID PRIMARY KEY REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    total_reports_made INTEGER DEFAULT 0 NOT NULL,
    reports_upheld     INTEGER DEFAULT 0 NOT NULL,
    reports_dismissed  INTEGER DEFAULT 0 NOT NULL,
    accuracy_rate      NUMERIC(5,2) GENERATED ALWAYS AS (
        CASE
            WHEN total_reports_made > 0
            THEN (reports_upheld::NUMERIC / total_reports_made * 100)
            ELSE 0
        END
    ) STORED,
    last_report_at     TIMESTAMP WITH TIME ZONE,
    is_report_banned   BOOLEAN DEFAULT FALSE NOT NULL,
    report_ban_reason  TEXT,
    report_ban_until   TIMESTAMP WITH TIME ZONE,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ---------------------------------------------------------------------
-- 8.5 moderation_action_templates - Action message templates
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS moderation_action_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type     moderation_action_enum NOT NULL UNIQUE,
    default_message TEXT NOT NULL,
    description     TEXT,
    example_message TEXT,
    display_order   INTEGER DEFAULT 0 NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ---------------------------------------------------------------------
-- 8.6 dismissal_reason_templates - Dismissal message templates
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dismissal_reason_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reason_code     dismissal_reason_enum NOT NULL UNIQUE,
    default_message TEXT NOT NULL,
    description     TEXT,
    example_message TEXT,
    display_order   INTEGER DEFAULT 0 NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- =====================================================================
-- PART 9: MODERATION QUEUE, LOGS, WARNINGS, RESTRICTIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 9.1 moderation_queue - System/AI flags
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS moderation_queue (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source               queue_source_enum NOT NULL,
    flagged_by           UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    flagged_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    target_type          report_target_type_enum NOT NULL,
    target_id            UUID NOT NULL,
    reason               TEXT NOT NULL,
    ai_confidence_score  DECIMAL(3,2),
    cleared_at           TIMESTAMP WITH TIME ZONE,
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ---------------------------------------------------------------------
-- 9.2 moderation_tiers - Role-based permissions
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS moderation_tiers (
    tier_name      VARCHAR(50) PRIMARY KEY,
    allowed_actions JSONB NOT NULL,
    action_limits  JSONB DEFAULT '{}'
    );

-- ---------------------------------------------------------------------
-- 9.3 moderation_log - Full audit trail
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS moderation_log (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    moderator_id         UUID NOT NULL REFERENCES app_users(keycloak_id),
    action_type          moderation_action_enum NOT NULL,
    action_description   VARCHAR(255) NOT NULL,
    rationale            TEXT NOT NULL,
    target_user_id       UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    target_post_id       UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
    target_thread_id     UUID REFERENCES forum_threads(id) ON DELETE SET NULL,
    report_id            UUID REFERENCES content_reports(id) ON DELETE SET NULL,
    metadata             JSONB,
    visibility           visibility_enum DEFAULT 'MODERATORS_ONLY' NOT NULL,
    expires_at           TIMESTAMP WITH TIME ZONE,
    is_automated         BOOLEAN DEFAULT FALSE NOT NULL,
    automation_rule_id   UUID,
    appeal_allowed       BOOLEAN DEFAULT FALSE NOT NULL,
    appeal_deadline      TIMESTAMP WITH TIME ZONE,
    action_taken_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ---------------------------------------------------------------------
-- 9.4 warning_type_definitions - Reference data for warnings
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS warning_type_definitions (
    warning_type   warning_type_enum PRIMARY KEY,
    display_name   VARCHAR(50) NOT NULL,
    description    TEXT NOT NULL,
    severity_level INTEGER NOT NULL
    );

-- ---------------------------------------------------------------------
-- 9.5 user_warnings - User warnings
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_warnings (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    warned_by         UUID NOT NULL REFERENCES app_users(keycloak_id),
    warning_type      warning_type_enum NOT NULL,
    warning_text      TEXT NOT NULL,
    related_post_id   UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
    related_thread_id UUID REFERENCES forum_threads(id) ON DELETE SET NULL,
    related_report_id UUID REFERENCES content_reports(id) ON DELETE SET NULL,
    warned_at         TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    acknowledged_at   TIMESTAMP WITH TIME ZONE,
    expires_at        TIMESTAMP WITH TIME ZONE,
    is_active         BOOLEAN DEFAULT TRUE NOT NULL
);

-- ---------------------------------------------------------------------
-- 9.6 user_restrictions - Mutes, suspensions, bans
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_restrictions (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    restriction_type       restriction_type_enum NOT NULL,
    reason                 TEXT NOT NULL,
    imposed_by             UUID NOT NULL REFERENCES app_users(keycloak_id),
    related_report_id      UUID REFERENCES content_reports(id) ON DELETE SET NULL,
    restricted_category_id UUID REFERENCES forum_categories(id) ON DELETE CASCADE,
    starts_at              TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at             TIMESTAMP WITH TIME ZONE,
    is_active              BOOLEAN DEFAULT TRUE NOT NULL,
    lifted_at              TIMESTAMP WITH TIME ZONE,
    lifted_by              UUID REFERENCES app_users(keycloak_id),
    lift_reason            TEXT
);

-- ---------------------------------------------------------------------
-- 9.7 moderation_rules - Automated moderation rules (schema)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS moderation_rules (
                                                id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name            VARCHAR(100) NOT NULL,
    description          TEXT,
    trigger_conditions   JSONB NOT NULL,
    action_type          moderation_action_enum NOT NULL,
    action_parameters    JSONB,
    priority             INTEGER DEFAULT 0 NOT NULL,
    is_active            BOOLEAN DEFAULT TRUE NOT NULL,
    created_by           UUID NOT NULL REFERENCES app_users(keycloak_id),
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_triggered_at    TIMESTAMP,
    trigger_count        INTEGER DEFAULT 0 NOT NULL
    );

-- =====================================================================
-- PART 10: ROLE & GROUP CONFIGURATIONS
-- =====================================================================

CREATE TABLE IF NOT EXISTS role_configurations (
                                                   role_name    realm_role_enum PRIMARY KEY,
                                                   capabilities JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS group_configurations (
                                                    group_path   groups_enum PRIMARY KEY,
                                                    capabilities JSONB NOT NULL DEFAULT '{}'
);

-- =====================================================================
-- PART 11: DISCOVERY & SUPPORT GRAPH
-- =====================================================================

-- ---------------------------------------------------------------------
-- 11.1 thread_bookmarks - Personal bookmarks
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS thread_bookmarks (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    thread_id  UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
    notes      TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (user_id, thread_id)
);

-- ---------------------------------------------------------------------
-- 11.2 user_connections - Mutual connections
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_connections (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_1               UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    user_2               UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    initiated_by         UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    status               connection_status_enum NOT NULL DEFAULT 'PENDING',
    notification_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_1, user_2),
    CONSTRAINT chk_no_self_connection CHECK (user_1 <> user_2),
    CONSTRAINT chk_initiated_by_is_one_of_users CHECK (initiated_by = user_1 OR initiated_by = user_2)
);

-- ---------------------------------------------------------------------
-- 11.3 focus_categories - Category curation
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS focus_categories (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    category_id          UUID NOT NULL REFERENCES forum_categories(id) ON DELETE CASCADE,
    notification_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (user_id, category_id)
);

-- ---------------------------------------------------------------------
-- 11.4 watch_threads - Thread watches
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS watch_threads (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    thread_id            UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
    notification_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (user_id, thread_id)
);

-- =====================================================================
-- PART 12: NOTIFICATIONS
-- =====================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id         UUID NOT NULL REFERENCES app_users(keycloak_id) ON DELETE CASCADE,
    notification_type    notification_type_enum NOT NULL,
    title                VARCHAR(255) NOT NULL,
    message              TEXT NOT NULL,
    action_url           VARCHAR(500),
    related_user_id      UUID REFERENCES app_users(keycloak_id) ON DELETE SET NULL,
    related_post_id      UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
    related_thread_id    UUID REFERENCES forum_threads(id) ON DELETE SET NULL,
    related_category_id  UUID REFERENCES forum_categories(id) ON DELETE SET NULL,
    sent_via             TEXT[] DEFAULT ARRAY['in_app'],
    is_read              BOOLEAN DEFAULT FALSE NOT NULL,
    read_at              TIMESTAMP WITH TIME ZONE,
    is_batched           BOOLEAN DEFAULT FALSE,
    batch_count          INTEGER,
    batch_metadata       JSONB,
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at           TIMESTAMP WITH TIME ZONE GENERATED ALWAYS AS (created_at + INTERVAL '90 days') STORED
);