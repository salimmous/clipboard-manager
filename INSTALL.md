# تثبيت مدير الحافظة

## طريقة التثبيت السريع

### الخطوة 1: تحميل التطبيق
1. اذهب إلى [صفحة الإصدارات](https://github.com/salimmous/clipboard-manager/releases)
2. حمل أحدث إصدار `ClipboardManager-v1.0.1.zip`

### الخطوة 2: فك الضغط والتثبيت
1. فك ضغط الملف المحمل
2. اسحب `ClipboardManager.app` إلى مجلد `Applications`
3. افتح التطبيق من مجلد التطبيقات

### الخطوة 3: السماح بتشغيل التطبيق
إذا ظهرت رسالة أمان:
1. اذهب إلى `System Preferences` > `Security & Privacy`
2. اضغط على `Open Anyway` بجانب اسم التطبيق

## التثبيت عبر Terminal

```bash
# تحميل أحدث إصدار
curl -L -o ClipboardManager.zip https://github.com/salimmous/clipboard-manager/releases/download/v1.0.1/ClipboardManager-v1.0.1.zip

# فك الضغط
unzip ClipboardManager.zip

# نقل إلى مجلد التطبيقات
mv ClipboardManager.app /Applications/

# تشغيل التطبيق
open /Applications/ClipboardManager.app
```

## المتطلبات
- macOS 10.15 أو أحدث
- 50 MB مساحة فارغة

## الميزات
- ✅ حفظ تلقائي للحافظة
- ✅ تحديثات تلقائية
- ✅ واجهة سهلة الاستخدام
- ✅ بحث سريع في المحفوظات
- ✅ اختصارات لوحة المفاتيح

## المساعدة
إذا واجهت مشاكل في التثبيت:
1. تأكد من أن macOS محدث
2. تحقق من وجود مساحة كافية
3. أعد تشغيل الجهاز وحاول مرة أخرى

## إلغاء التثبيت
لإزالة التطبيق:
```bash
rm -rf /Applications/ClipboardManager.app
```

---

**ملاحظة**: التطبيق يدعم التحديثات التلقائية، لذا ستحصل على أحدث الميزات تلقائياً!