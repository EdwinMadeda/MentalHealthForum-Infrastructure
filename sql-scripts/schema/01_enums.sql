-- =====================================================================
-- PART 2: ENUMS (Alphabetical, idempotent)
-- =====================================================================

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'connection_status_enum') THEN
CREATE TYPE connection_status_enum AS ENUM ('PENDING', 'ACCEPTED', 'DECLINED');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'content_warning_enum') THEN
CREATE TYPE content_warning_enum AS ENUM (
            'NONE', 'SELF_HARM', 'SUICIDE', 'TRAUMA', 'ABUSE',
            'VIOLENCE', 'SUBSTANCE_USE', 'EATING_DISORDERS'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dismissal_reason_enum') THEN
CREATE TYPE dismissal_reason_enum AS ENUM (
            'FALSE_POSITIVE', 'NO_VIOLATION', 'ALREADY_HANDLED', 'CONTENT_GONE',
            'INSUFFICIENT_EVIDENCE', 'USER_EDUCATED', 'DUPLICATE_REPORT',
            'ALLOWED_CONTENT', 'PROTECTED_CONTENT'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'edit_reason_enum') THEN
CREATE TYPE edit_reason_enum AS ENUM (
            'TYPO_FIX', 'ADDED_CONTEXT', 'CLARIFICATION', 'REMOVED_PERSONAL_INFO',
            'CONTENT_POLICY_VIOLATION', 'FORMATTING', 'OTHER', 'CONTENT_WARNING_ADDED'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'groups_enum') THEN
CREATE TYPE groups_enum AS ENUM (
            'members', 'members/new', 'members/active', 'members/trusted',
            'moderators', 'moderators/peer', 'moderators/professional', 'administrators'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'moderation_action_enum') THEN
CREATE TYPE moderation_action_enum AS ENUM (
            'POST_DELETED', 'POST_EDITED', 'POST_FLAGGED', 'POST_CONTENT_WARNING_ADDED',
            'POST_RESTORED', 'POST_PERMANENTLY_DELETED', 'VIEW_DELETED_POSTS',
            'THREAD_LOCKED', 'THREAD_UNLOCKED', 'THREAD_DELETED', 'THREAD_MOVED',
            'THREAD_MERGED', 'THREAD_SPLIT', 'THREAD_STATUS_CHANGED', 'THREAD_FEATURED',
            'THREAD_UNFEATURED', 'THREAD_TYPE_CHANGED', 'THREAD_STICKY_TOGGLED',
            'THREAD_RESTORED', 'THREAD_PERMANENTLY_DELETED', 'THREAD_METADATA_EDITED',
            'THREAD_CONTENT_WARNING_ADDED', 'THREAD_ARCHIVED', 'THREAD_UNARCHIVED',
            'THREAD_SOFT_DELETED', 'THREAD_BEST_ANSWER_SET', 'THREAD_BEST_ANSWER_CLEARED',
            'VIEW_DELETED_THREADS',
            'USER_WARNED', 'USER_MUTED', 'USER_UNMUTED', 'USER_SUSPENDED',
            'USER_UNSUSPENDED', 'USER_BANNED', 'USER_UNBANNED', 'USER_REPUTATION_ADJUSTED',
            'ROLE_GRANTED', 'ROLE_REVOKED', 'GROUP_ADDED', 'GROUP_REMOVED',
            'REPORT_ASSIGNED', 'REPORT_ESCALATED', 'REPORT_ACTIONED', 'REPORT_DISMISSED',
            'REPORT_DETAILS_UPDATED',
            'BULK_ACTION',
            'CATEGORY_ACCESS_CHANGED', 'CATEGORY_CREATED', 'CATEGORY_UPDATED',
            'CATEGORY_SOFT_DELETED', 'CATEGORY_REACTIVATED', 'CATEGORY_PURGED',
            'CATEGORY_VIEW_INACTIVE', 'CATEGORY_PURGE_OLD',
            'CATEGORY_TAG_CREATED', 'CATEGORY_TAG_UPDATED', 'CATEGORY_TAG_DELETED',
            'CATEGORY_TAG_ASSIGNED', 'CATEGORY_TAG_UNASSIGNED', 'CATEGORY_TAG_REPLACED',
            'BEST_ANSWER_SET', 'BEST_ANSWER_CLEARED'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
CREATE TYPE notification_type_enum AS ENUM ('REPLY', 'REACTION', 'FOLLOW', 'MODERATION', 'SYSTEM');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'onboarding_stage_enum') THEN
CREATE TYPE onboarding_stage_enum AS ENUM (
            'AWAITING_VERIFICATION', 'AWAITING_PASSWORD_RESET', 'AWAITING_PROFILE_COMPLETION'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'otp_purpose_enum') THEN
CREATE TYPE otp_purpose_enum AS ENUM ('FORGOT_PASSWORD', 'ADMIN_2FA');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'post_type_enum') THEN
CREATE TYPE post_type_enum AS ENUM ('REPLY', 'ANSWER', 'SYSTEM_MESSAGE', 'MODERATOR_NOTE');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'profile_visibility_enum') THEN
CREATE TYPE profile_visibility_enum AS ENUM ('MEMBERS_ONLY', 'PRIVATE', 'CONNECTED_ONLY');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'queue_source_enum') THEN
CREATE TYPE queue_source_enum AS ENUM ('MODERATOR', 'AI', 'SYSTEM');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reaction_enum') THEN
CREATE TYPE reaction_enum AS ENUM (
            'UPVOTE', 'HELPFUL', 'SUPPORTIVE', 'INSIGHTFUL', 'HUGS', 'RELATABLE', 'BRAVE', 'HOPE'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'realm_role_enum') THEN
CREATE TYPE realm_role_enum AS ENUM ('moderator', 'forum_member', 'peer_supporter', 'trusted_member', 'admin');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'report_category_enum') THEN
CREATE TYPE report_category_enum AS ENUM (
            'SPAM', 'HARASSMENT', 'SELF_HARM', 'SUICIDE', 'VIOLENCE',
            'MISINFORMATION', 'PRIVACY_VIOLATION', 'INAPPROPRIATE', 'OTHER'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'report_reason_code_enum') THEN
CREATE TYPE report_reason_code_enum AS ENUM (
            'SPAM_PROMOTIONAL', 'SPAM_OFFTOPIC', 'HARASSMENT_BULLYING', 'HARASSMENT_PERSONAL_ATTACK',
            'SELF_HARM_DETAILED', 'SUICIDE_EXPRESSION', 'VIOLENCE_THREATS',
            'MISINFORMATION_DANGEROUS', 'PRIVACY_DOXING', 'INAPPROPRIATE_CONTENT', 'OTHER_REASON'
        );
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'report_status_enum') THEN
CREATE TYPE report_status_enum AS ENUM ('PENDING', 'UNDER_REVIEW', 'ACTION_TAKEN', 'DISMISSED', 'ESCALATED');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'report_target_type_enum') THEN
CREATE TYPE report_target_type_enum AS ENUM ('THREAD', 'POST', 'USER');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'restriction_type_enum') THEN
CREATE TYPE restriction_type_enum AS ENUM ('MUTE', 'POSTING_BAN', 'CATEGORY_BAN', 'SUSPENSION', 'PERMANENT_BAN');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'severity_enum') THEN
CREATE TYPE severity_enum AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'support_role_enum') THEN
CREATE TYPE support_role_enum AS ENUM ('NOT_SPECIFIED', 'SEEKING_SUPPORT', 'OFFERING_SUPPORT', 'BOTH');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'thread_status_enum') THEN
CREATE TYPE thread_status_enum AS ENUM ('OPEN', 'RESOLVED', 'CLOSED', 'ARCHIVED');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'thread_type_enum') THEN
CREATE TYPE thread_type_enum AS ENUM ('DISCUSSION', 'QUESTION', 'CRISIS_SUPPORT', 'PEER_REVIEW', 'POLL');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'visibility_enum') THEN
CREATE TYPE visibility_enum AS ENUM ('PUBLIC', 'MODERATORS_ONLY', 'ADMIN_ONLY');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'warning_type_enum') THEN
CREATE TYPE warning_type_enum AS ENUM ('INFORMAL', 'FORMAL', 'FINAL', 'POLICY_VIOLATION');
END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_status_enum') THEN
CREATE TYPE account_status_enum AS ENUM ('ACTIVE', 'PENDING_DELETION', 'PURGED');
END IF;
END $$;