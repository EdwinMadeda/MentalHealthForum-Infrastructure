-- =====================================================================
-- PART 13: CIRCULAR DEPENDENCIES (best_answer_post_id)
-- =====================================================================

-- Clear invalid references first
UPDATE forum_threads
SET best_answer_post_id = NULL
WHERE best_answer_post_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM forum_posts
    WHERE forum_posts.id = forum_threads.best_answer_post_id
);

ALTER TABLE forum_threads
    ADD CONSTRAINT fk_best_answer_post
        FOREIGN KEY (best_answer_post_id, id)
            REFERENCES forum_posts (id, thread_id)
            ON DELETE SET NULL;

COMMENT ON CONSTRAINT fk_best_answer_post ON forum_threads IS 'Best answer must be a post from the same thread';

-- Foreign key to reason definitions (soft reference, keeps logs if template deleted)
ALTER TABLE user_audit_log
ADD CONSTRAINT fk_audit_log_reason_definition
FOREIGN KEY (reason_definition_id)
REFERENCES user_audit_reason_definitions(id)
ON DELETE SET NULL;