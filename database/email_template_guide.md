# تخصيص إيميل التأكيد في Supabase

## الخطوات

### 1. افتح Supabase Dashboard

- روح لـ <https://supabase.com/dashboard>
- اختار مشروع SCA

### 2. روح لـ Authentication → Email Templates

### 3. اختار "Confirm signup"

### 4. غير الـ Subject

```text
مرحباً بك في Smart Call Assistant! - تأكيد الحساب
```

### 5. غير Template

```html
<h2>مرحباً بك في Smart Call Assistant! 🎉</h2>

<p>أهلاً وسهلاً بيك في تطبيق SCA!</p>

<p>شكراً لتسجيلك معانا. عشان تفعّل حسابك، اضغط على الزر ده:</p>

<p style="text-align: center; margin: 30px 0;">
  <a href="{{ .ConfirmationURL }}" 
     style="background-color: #4CAF50; 
            color: white; 
            padding: 15px 32px; 
            text-decoration: none; 
            font-size: 16px; 
            border-radius: 8px;">
    تفعيل الحساب
  </a>
</p>

<p>أو انسخ الرابط ده:</p>
<p style="word-break: break-all; color: #666;">{{ .ConfirmationURL }}</p>

<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">

<p style="color: #888; font-size: 12px;">
  لو مش انت اللي سجلت الحساب ده، تجاهل الإيميل ده.
</p>

<p style="color: #888; font-size: 12px;">
  فريق Smart Call Assistant
</p>
```

### 6. اضغط Save

---

## ملاحظات

- متغير `{{ .ConfirmationURL }}` بيتحط تلقائي من Supabase
- تقدر تضيف الشعار بتاعك لو عايز
- الألوان ممكن تغيرها زي ما تحب
