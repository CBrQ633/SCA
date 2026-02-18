-- 🕒 AUTO-CLEANUP: DELETE OLD NEWS
-- Run this in your Supabase SQL Editor
-- 1. Create a function to delete news older than 3 days
CREATE OR REPLACE FUNCTION delete_old_news() RETURNS void AS $$ BEGIN
DELETE FROM public.news_announcements
WHERE created_at < NOW() - INTERVAL '3 days';
END;
$$ LANGUAGE plpgsql;
-- 2. NOTE: To automate this, you can:
-- A) Use Supabase "Cron" (Safe way if pg_cron is enabled):
--    SELECT cron.schedule('0 0 * * *', 'SELECT delete_old_news()');
-- B) Or just run this manually if you want to clear them now:
--    SELECT delete_old_news();
-- C) Database policy to hide them if they are old (Alternative to deletion)
DROP POLICY IF EXISTS "Anyone can view active news" ON public.news_announcements;
CREATE POLICY "Anyone can view active news" ON public.news_announcements FOR
SELECT USING (
        is_active = true
        AND created_at > NOW() - INTERVAL '3 days'
    );
-- ✅ Done! News will now only show for the last 3 days.