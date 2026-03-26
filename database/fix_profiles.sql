-- SCA DATABASE REPAIR SCRIPT (FIX PROFILES & RLS)
-- هدا السكريبت يقوم بإصلاح جدول profiles وضمان ظهور كافة المستخدمين للأدمن
-- 1. التأكد من وجود جدول profiles بالأعمدة الصحيحة
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  role TEXT DEFAULT 'sales_user',
  -- 'sales_user', 'team_leader', 'admin'
  subscription_status TEXT DEFAULT 'inactive',
  -- 'active', 'inactive', 'pending', 'rejected'
  subscription_reject_reason TEXT,
  subscription_start TIMESTAMP WITH TIME ZONE,
  subscription_end TIMESTAMP WITH TIME ZONE,
  current_device_id TEXT,
  leader_id UUID REFERENCES public.profiles(id) ON DELETE
  SET NULL,
    sca_id TEXT UNIQUE,
    monthly_target INTEGER DEFAULT 0,
    fcm_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
-- 2. تعطيل RLS مؤقتاً للإصلاح
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
-- 3. دالة فحص الأدمن (لمنع التكرار في الحماية)
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$ BEGIN RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 4. إعداد الحماية (RLS Policies) لجدول profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all users" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update users" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles FOR
SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all users" ON public.profiles FOR
SELECT USING (public.is_admin());
CREATE POLICY "Admins can update users" ON public.profiles FOR
UPDATE USING (public.is_admin());
-- 5. تفعيل RLS مرة أخرى
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
-- 6. تريجر لإنشاء الملف الشخصي تلقائياً عند التسجيل (للمستخدمين الجدد)
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER AS $$ BEGIN
INSERT INTO public.profiles (id, email, full_name, sca_id)
VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    'SCA-' || upper(substring(replace(NEW.id::text, '-', ''), 1, 6))
  );
RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER
INSERT ON auth.users FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
-- 7. نقل المستخدمين الحاليين (إذا لم يكن لديهم ملف شخصي)
INSERT INTO public.profiles (id, email, full_name, sca_id)
SELECT id,
  email,
  raw_user_meta_data->>'full_name',
  'SCA-' || upper(substring(replace(id::text, '-', ''), 1, 6))
FROM auth.users
WHERE id NOT IN (
    SELECT id
    FROM public.profiles
  ) ON CONFLICT (id) DO NOTHING;
-- 8. تعيين الأدمن (استبدل البريد ببريدك الخاص)
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'it@babeco.org';
-- ملاحظة: يمكنك تغيير الايميل أعلاه ليطابق حسابك