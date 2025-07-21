#!/bin/bash

# مثبت مدير الحافظة التلقائي
# Clipboard Manager Auto Installer

echo "🚀 بدء تثبيت مدير الحافظة..."
echo "🚀 Starting Clipboard Manager installation..."

# التحقق من وجود curl
if ! command -v curl &> /dev/null; then
    echo "❌ curl غير مثبت. يرجى تثبيت curl أولاً"
    echo "❌ curl is not installed. Please install curl first"
    exit 1
fi

# إنشاء مجلد مؤقت
TEMP_DIR=$(mktemp -d)
echo "📁 إنشاء مجلد مؤقت: $TEMP_DIR"

# تحميل أحدث إصدار
echo "⬇️ تحميل أحدث إصدار..."
cd "$TEMP_DIR"
curl -L -o ClipboardManager.zip "https://github.com/salimmous/clipboard-manager/releases/download/v1.0.1/ClipboardManager-v1.0.1.zip"

if [ $? -ne 0 ]; then
    echo "❌ فشل في تحميل التطبيق"
    echo "❌ Failed to download the app"
    exit 1
fi

# فك الضغط
echo "📦 فك ضغط الملف..."
unzip -q ClipboardManager.zip

if [ $? -ne 0 ]; then
    echo "❌ فشل في فك ضغط الملف"
    echo "❌ Failed to extract the file"
    exit 1
fi

# التحقق من وجود مجلد Applications
if [ ! -d "/Applications" ]; then
    echo "❌ مجلد Applications غير موجود"
    echo "❌ Applications folder not found"
    exit 1
fi

# نسخ التطبيق إلى مجلد Applications
echo "📱 تثبيت التطبيق في مجلد Applications..."
cp -R ClipboardManager.app /Applications/

if [ $? -ne 0 ]; then
    echo "❌ فشل في نسخ التطبيق إلى مجلد Applications"
    echo "❌ Failed to copy app to Applications folder"
    echo "💡 جرب تشغيل الأمر بصلاحيات المدير: sudo ./install.sh"
    echo "💡 Try running with admin privileges: sudo ./install.sh"
    exit 1
fi

# تنظيف الملفات المؤقتة
echo "🧹 تنظيف الملفات المؤقتة..."
rm -rf "$TEMP_DIR"

# رسالة النجاح
echo "✅ تم تثبيت مدير الحافظة بنجاح!"
echo "✅ Clipboard Manager installed successfully!"
echo ""
echo "🎉 يمكنك الآن تشغيل التطبيق من:"
echo "🎉 You can now run the app from:"
echo "   - مجلد التطبيقات (Applications folder)"
echo "   - أو عبر Terminal: open /Applications/ClipboardManager.app"
echo ""
echo "📋 الميزات المتاحة:"
echo "📋 Available features:"
echo "   ✓ حفظ تلقائي للحافظة"
echo "   ✓ تحديثات تلقائية"
echo "   ✓ بحث سريع"
echo "   ✓ اختصارات لوحة المفاتيح"
echo ""
echo "🚀 هل تريد تشغيل التطبيق الآن؟ (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "🎯 تشغيل التطبيق..."
    open /Applications/ClipboardManager.app
fi

echo "🎊 شكراً لاستخدام مدير الحافظة!"
echo "🎊 Thank you for using Clipboard Manager!"