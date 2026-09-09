-- =====================================================================
-- PART 18: SEED DATA
-- =====================================================================

-- ---------------------------------------------------------------------
-- 18.1 audit_reason_definitions
-- ---------------------------------------------------------------------
INSERT INTO audit_reason_definitions (key, description, action_type, sort_order) VALUES
                                                                                                    -- Promotions
                                                                                                    ('EXCEPTIONAL_CONTRIBUTION', 'Exceptional contribution to the community', 'PROMOTION', 10),
                                                                                                    ('TRUSTED_ESTABLISHED', 'User has established trust over time', 'PROMOTION', 20),
                                                                                                    ('PROFESSIONAL_CREDENTIALS', 'User has verified professional credentials', 'PROMOTION', 30),
                                                                                                    ('MODERATOR_NOMINATION', 'Nominated by fellow moderators', 'PROMOTION', 40),

                                                                                                    -- Demotions
                                                                                                    ('POLICY_VIOLATION', 'Violation of community guidelines', 'DEMOTION', 10),
                                                                                                    ('INACTIVITY', 'Inactive for an extended period', 'DEMOTION', 20),
                                                                                                    ('REQUESTED_DEMOTION', 'User requested demotion', 'DEMOTION', 30),

                                                                                                    -- Disable/Enable
                                                                                                    ('TEMP_SUSPENSION', 'Temporary suspension pending review', 'DISABLED', 10),
                                                                                                    ('ACCOUNT_RECOVERY', 'Account recovered after verification', 'ENABLED', 10),

                                                                                                    -- General
                                                                                                    ('ADMIN_CORRECTION', 'Administrative correction', 'GROUP_CHANGED', 10),
                                                                                                    ('SYSTEM_AUTO', 'System automated action', 'CREATED', 10);




-- ---------------------------------------------------------------------
-- 18.2 thread_type_definitions
-- ---------------------------------------------------------------------
INSERT INTO thread_type_definitions (thread_type, display_name, description, icon_hint, example) VALUES
                                                                                                     ('DISCUSSION', 'Discussion', 'Open-ended conversation on a topic. No specific outcome expected.', 'chat', 'Share your thoughts on coping with workplace anxiety'),
                                                                                                     ('QUESTION', 'Question', 'Seeking specific answers or advice from the community.', 'help-circle', 'How do I handle panic attacks in public?'),
                                                                                                     ('CRISIS_SUPPORT', 'Crisis Support', 'Urgent support needed. Peer supporters and moderators will be notified.', 'alert-circle', 'Feeling overwhelmed and need immediate support'),
                                                                                                     ('PEER_REVIEW', 'Peer Review', 'Sharing your story or approach for feedback from others.', 'users', 'I wrote about my journey with depression, would love your thoughts'),
                                                                                                     ('POLL', 'Poll', 'Community survey to gather opinions or preferences.', 'bar-chart', 'What coping strategies work best for you?')
    ON CONFLICT (thread_type) DO NOTHING;

-- ---------------------------------------------------------------------
-- 18.3 thread_status_definitions
-- ---------------------------------------------------------------------
INSERT INTO thread_status_definitions (thread_status, display_name, description, user_visible) VALUES
                                                                                                   ('OPEN', 'Open', 'Active discussion, accepting new posts', TRUE),
                                                                                                   ('RESOLVED', 'Resolved', 'Question answered or issue addressed', TRUE),
                                                                                                   ('CLOSED', 'Closed', 'No longer accepting posts, but still visible', TRUE),
                                                                                                   ('ARCHIVED', 'Archived', 'Old/inactive, hidden from main view but searchable', FALSE)
    ON CONFLICT (thread_status) DO NOTHING;

-- ---------------------------------------------------------------------
-- 18.4 reaction_definitions
-- ---------------------------------------------------------------------
INSERT INTO reaction_definitions (reaction_type, display_name, icon_class, description, reputation_points, available_to_roles, sort_order) VALUES
                                                                                                                                               ('UPVOTE', 'Upvote', '👍', 'General agreement or approval', 1, NULL, 1),
                                                                                                                                               ('HELPFUL', 'Helpful', '💡', 'This provided actionable advice', 3, NULL, 2),
                                                                                                                                               ('SUPPORTIVE', 'Supportive', '❤️', 'Offering emotional support', 2, NULL, 3),
                                                                                                                                               ('INSIGHTFUL', 'Insightful', '🧠', 'New perspective or deep insight', 3, NULL, 4),
                                                                                                                                               ('HUGS', 'Hugs', '🤗', 'Virtual comfort and warmth', 2, NULL, 5),
                                                                                                                                               ('RELATABLE', 'Relatable', '😔', 'I have the same experience', 1, NULL, 6),
                                                                                                                                               ('BRAVE', 'Brave', '🦁', 'Courage to share vulnerably', 2, NULL, 7),
                                                                                                                                               ('HOPE', 'Hope', '🌈', 'This gives me hope', 2, NULL, 8)
    ON CONFLICT (reaction_type) DO NOTHING;

-- ---------------------------------------------------------------------
-- 18.5 report_templates
-- ---------------------------------------------------------------------
TRUNCATE report_templates RESTART IDENTITY CASCADE;
INSERT INTO report_templates (report_category, template_text, requires_details, auto_severity, display_order, reason_code, example_details) VALUES
                                                                                                                                                ('SPAM', 'This post contains spam or promotional content', FALSE, 'LOW', 1, 'SPAM_PROMOTIONAL', NULL),
                                                                                                                                                ('SPAM', 'This post is off-topic or irrelevant to the discussion', FALSE, 'LOW', 2, 'SPAM_OFFTOPIC', NULL),
                                                                                                                                                ('HARASSMENT', 'This post harasses or bullies another user', TRUE, 'HIGH', 3, 'HARASSMENT_BULLYING', 'Please provide specific examples of the harassing behavior'),
                                                                                                                                                ('HARASSMENT', 'This post contains personal attacks against another user', TRUE, 'HIGH', 4, 'HARASSMENT_PERSONAL_ATTACK', 'Please quote the specific personal attack'),
                                                                                                                                                ('SELF_HARM', 'This post discusses self-harm in concerning detail', TRUE, 'CRITICAL', 5, 'SELF_HARM_DETAILED', 'Please describe what concerns you about this content'),
                                                                                                                                                ('SUICIDE', 'This post expresses suicidal thoughts or plans', TRUE, 'CRITICAL', 6, 'SUICIDE_EXPRESSION', 'Is the user seeking help or expressing intent?'),
                                                                                                                                                ('VIOLENCE', 'This post contains threats of violence', TRUE, 'CRITICAL', 7, 'VIOLENCE_THREATS', 'Please quote the specific threat'),
                                                                                                                                                ('MISINFORMATION', 'This post contains dangerous mental health misinformation', TRUE, 'HIGH', 8, 'MISINFORMATION_DANGEROUS', 'Please explain why this information is harmful'),
                                                                                                                                                ('PRIVACY_VIOLATION', 'This post shares someone''s personal information without consent', TRUE, 'HIGH', 9, 'PRIVACY_DOXING', 'What personal information was shared?'),
                                                                                                                                                ('INAPPROPRIATE', 'This post contains inappropriate content for this community', TRUE, 'MEDIUM', 10, 'INAPPROPRIATE_CONTENT', 'Please explain why this content is inappropriate'),
                                                                                                                                                ('OTHER', 'Other reason (please explain in detail)', TRUE, 'MEDIUM', 11, 'OTHER_REASON', 'Please provide a detailed explanation');

-- ---------------------------------------------------------------------
-- 18.6 moderation_action_templates
-- ---------------------------------------------------------------------
INSERT INTO moderation_action_templates (action_type, default_message, description, example_message, display_order) VALUES
                                                                                                                        ('POST_DELETED', 'Your post has been removed for violating community guidelines.', 'Remove inappropriate content', 'The post contained personal attacks which are not allowed', 1),
                                                                                                                        ('POST_EDITED', 'Your post has been edited by a moderator to comply with community guidelines.', 'Moderator edits to remove violating content', 'Edited to remove an offensive phrase', 2),
                                                                                                                        ('POST_FLAGGED', 'Your post has been flagged for review due to potential guideline violations.', 'Add flag/notice to post for further review', 'Flagged for potential misinformation', 3),
                                                                                                                        ('POST_CONTENT_WARNING_ADDED', 'A content warning has been added to your post to help users make informed choices.', 'Add trigger warning overlay', 'Added "self-harm" content warning', 4),
                                                                                                                        ('POST_RESTORED', 'Your post has been restored after review. We apologize for any inconvenience.', 'Undo a deletion', 'Post was incorrectly removed as spam', 5),
                                                                                                                        ('THREAD_LOCKED', 'This thread has been locked as it violates community guidelines.', 'Prevent new replies', 'Discussion became heated; locked to prevent escalation', 6),
                                                                                                                        ('THREAD_UNLOCKED', 'This thread has been unlocked and is now open for replies.', 'Reopen a locked thread', 'Thread was locked in error; now reopened', 7),
                                                                                                                        ('THREAD_DELETED', 'This thread has been removed for violating community guidelines.', 'Soft delete entire thread', 'Thread contained dangerous misinformation', 8),
                                                                                                                        ('THREAD_MOVED', 'This thread has been moved to a more appropriate category.', 'Move thread to different category', 'Moved from General to Self-Help category', 9),
                                                                                                                        ('THREAD_MERGED', 'Your thread has been merged with an existing discussion on the same topic.', 'Combine with another thread', 'Merged duplicate threads', 10),
                                                                                                                        ('THREAD_SPLIT', 'Some posts have been split from this thread to create a new discussion.', 'Split posts into new thread', 'Off-topic replies moved to separate thread', 11),
                                                                                                                        ('THREAD_STATUS_CHANGED', 'The status of this thread has been updated.', 'Change thread status', 'Thread marked as "RESOLVED"', 12),
                                                                                                                        ('THREAD_FEATURED', 'This thread has been featured as an important discussion.', 'Pin/promote thread', 'Featured for its helpful resources', 13),
                                                                                                                        ('THREAD_UNFEATURED', 'This thread is no longer featured.', 'Remove pin/promotion', 'Removed from featured after 30 days', 14),
                                                                                                                        ('USER_WARNED', 'You have received a formal warning for violating community guidelines.', 'Issue formal warning', 'Warning for repeatedly derailing discussions', 15),
                                                                                                                        ('USER_MUTED', 'You have been temporarily muted. You can read but cannot post for the specified duration.', 'Temporarily prevent posting', 'Muted for 24 hours after multiple violations', 16),
                                                                                                                        ('USER_UNMUTED', 'Your mute has been lifted. You may now post again.', 'Remove mute restriction', 'Mute expired or lifted early', 17),
                                                                                                                        ('USER_SUSPENDED', 'Your account has been temporarily suspended. You will regain access after the suspension period.', 'Temporary account suspension', 'Suspended for 7 days due to serious harassment', 18),
                                                                                                                        ('USER_UNSUSPENDED', 'Your suspension has been lifted. Welcome back.', 'End suspension early', 'Suspension lifted after successful appeal', 19),
                                                                                                                        ('USER_BANNED', 'Your account has been permanently banned for severe or repeated violations.', 'Permanent ban', 'Permanent ban for sharing self-harm methods', 20),
                                                                                                                        ('USER_UNBANNED', 'Your ban has been lifted. Please review community guidelines before posting.', 'Reverse permanent ban', 'Ban lifted after appeal', 21),
                                                                                                                        ('USER_REPUTATION_ADJUSTED', 'Your reputation score has been adjusted based on recent moderation actions.', 'Adjust user reputation', 'Reputation decreased by 50 points for spam', 22),
                                                                                                                        ('REPORT_ASSIGNED', 'Your report has been assigned to a moderator for review. We will update you once a decision has been made.', 'Report assigned to moderator', 'Report ID #123 assigned to Moderator Jane', 23),
                                                                                                                        ('REPORT_ACTIONED', 'Thank you for your report. Action has been taken based on your submission.', 'Report resolved with action', 'Post removed and user warned based on your report', 24),
                                                                                                                        ('REPORT_DISMISSED', 'Thank you for your report. After review, no action was taken.', 'Report closed without action', 'Report dismissed as no violation found', 25),
                                                                                                                        ('REPORT_ESCALATED', 'This report has been escalated to admin review due to its complexity or severity.', 'Report requires higher-level review', 'Escalated to admin due to potential legal implications', 26),
                                                                                                                        ('REPORT_DETAILS_UPDATED', 'Report details have been updated by a moderator.', 'Moderator updated report metadata', 'Severity changed from HIGH to CRITICAL after review', 27)
    ON CONFLICT (action_type) DO NOTHING;

-- ---------------------------------------------------------------------
-- 18.7 dismissal_reason_templates
-- ---------------------------------------------------------------------
INSERT INTO dismissal_reason_templates (reason_code, default_message, description, example_message, display_order) VALUES
                                                                                                                       ('FALSE_POSITIVE', 'This report was determined to be a false positive. No violation of community guidelines was found.', 'Content does not violate rules', 'Reported a post for "harassment" but it was politely disagreeing', 1),
                                                                                                                       ('NO_VIOLATION', 'After careful review, this content does not violate our community guidelines. No action will be taken.', 'Content is technically allowed', 'Discussion of sensitive mental health topics is permitted', 2),
                                                                                                                       ('ALREADY_HANDLED', 'This issue has already been addressed by moderators. The report is being closed.', 'Another moderator already acted', 'Another moderator already deleted the offending post', 3),
                                                                                                                       ('CONTENT_GONE', 'The reported content is no longer available or has been removed.', 'Content no longer exists', 'User deleted their own post before review', 4),
                                                                                                                       ('INSUFFICIENT_EVIDENCE', 'There is insufficient evidence to take action on this report at this time.', 'Cannot verify violation', 'No screenshots or clear evidence provided', 5),
                                                                                                                       ('USER_EDUCATED', 'The user has been privately contacted with guidance about community expectations. No formal action recorded.', 'Informal education', 'New user who didn''t know about self-promotion rule', 6),
                                                                                                                       ('DUPLICATE_REPORT', 'This report is a duplicate of an existing active report. Closing this instance.', 'Same content reported multiple times', 'Five users reported the same post; only one needs to stay open', 7),
                                                                                                                       ('ALLOWED_CONTENT', 'This content is explicitly allowed under our policies. Please review our guidelines.', 'Content is permitted by design', 'Reporting a support thread in a support category', 8),
                                                                                                                       ('PROTECTED_CONTENT', 'The reported behavior falls under protected discussion of mental health experiences. No violation.', 'Content is protected under safe space policy', 'User sharing their own struggle with self-harm (seeking help)', 9)
    ON CONFLICT (reason_code) DO NOTHING;

-- ---------------------------------------------------------------------
-- 18.8 moderation_tiers
-- ---------------------------------------------------------------------
INSERT INTO moderation_tiers (tier_name, allowed_actions, action_limits) VALUES
                                                                             ('moderator', '{
        "allowed_actions": [
            "POST_DELETED", "POST_EDITED", "POST_FLAGGED",
            "THREAD_LOCKED", "THREAD_UNLOCKED", "THREAD_MOVED",
            "USER_WARNED", "USER_MUTED", "REPORT_ASSIGNED", "REPORT_ACTIONED"
        ],
        "restrictions": {
            "max_mute_duration_hours": 24,
            "cannot_permanent_ban": true,
            "cannot_change_roles": true
        }
    }', '{}'),
                                                                             ('admin', '{
        "allowed_actions": [
            "POST_DELETED", "POST_EDITED", "POST_FLAGGED", "POST_RESTORED",
            "THREAD_LOCKED", "THREAD_UNLOCKED", "THREAD_DELETED", "THREAD_MOVED",
            "USER_WARNED", "USER_MUTED", "USER_SUSPENDED", "USER_BANNED",
            "USER_REPUTATION_ADJUSTED", "ROLE_GRANTED", "ROLE_REVOKED"
        ],
        "restrictions": {}
    }', '{}')
    ON CONFLICT (tier_name) DO NOTHING;

-- ---------------------------------------------------------------------
-- 18.9 warning_type_definitions
-- ---------------------------------------------------------------------
INSERT INTO warning_type_definitions (warning_type, display_name, description, severity_level) VALUES
                                                                                                   ('INFORMAL', 'Informal Reminder', 'Friendly nudge about community guidelines', 1),
                                                                                                   ('FORMAL', 'Formal Warning', 'Official warning on record', 2),
                                                                                                   ('FINAL', 'Final Warning', 'Last warning before suspension/ban', 3),
                                                                                                   ('POLICY_VIOLATION', 'Policy Violation', 'Specific community rule violated', 2)
    ON CONFLICT (warning_type) DO NOTHING;

-- ---------------------------------------------------------------------
-- 18.10 role_configurations
-- ---------------------------------------------------------------------
INSERT INTO role_configurations (role_name) VALUES
                                                ('moderator'), ('forum_member'), ('peer_supporter'), ('trusted_member'), ('admin')
    ON CONFLICT (role_name) DO NOTHING;

-- ---------------------------------------------------------------------
-- 18.11 group_configurations
-- ---------------------------------------------------------------------
INSERT INTO group_configurations (group_path) VALUES
                                                  ('members'), ('members/new'), ('members/active'), ('members/trusted'),
                                                  ('moderators'), ('moderators/peer'), ('moderators/professional'), ('administrators')
    ON CONFLICT (group_path) DO NOTHING;


