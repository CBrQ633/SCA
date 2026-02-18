-- 1. Add missing or misnamed columns to news_announcements
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'news_announcements'
        AND column_name = 'expiry_date'
) THEN
ALTER TABLE public.news_announcements
ADD COLUMN expiry_date TIMESTAMP WITH TIME ZONE;
END IF;
END $$;
-- 2. Ensure Storage Buckets exist (Public access for images)
-- Note: These usually need to be created via the Dashboard for initial setup, 
-- but we can ensure policies exist if the buckets are created.
-- Payment Proofs Bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('payment_proofs', 'payment_proofs', true) ON CONFLICT (id) DO NOTHING;
-- News Images Bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('news_images', 'news_images', true) ON CONFLICT (id) DO NOTHING;
-- 3. Storage Policies
-- Payment Proofs
CREATE POLICY "Public Access proofs" ON storage.objects FOR
SELECT USING (bucket_id = 'payment_proofs');
CREATE POLICY "Authenticated Upload proofs" ON storage.objects FOR
INSERT WITH CHECK (
        bucket_id = 'payment_proofs'
        AND auth.role() = 'authenticated'
    );
-- News Images
CREATE POLICY "Public Access news" ON storage.objects FOR
SELECT USING (bucket_id = 'news_images');
CREATE POLICY "Admin Upload news" ON storage.objects FOR ALL USING (
    bucket_id = 'news_images'
    AND (
        EXISTS (
            SELECT 1
            FROM public.users
            WHERE id = auth.uid()
                AND role = 'admin'
        )
    )
);