# 🎥 تعليمات إعداد مكالمات الفيديو - GoLive Screen (Agora)

## 📋 نظرة عامة
هذا الدليل يشرح كيفية إعداد نظام مكالمات الفيديو في تطبيقك باستخدام **Agora RTC Engine** و **Firebase Cloud Messaging**.

---

## ✨ لماذا Agora؟

### مقارنة الخدمات:
| الخدمة | الطبقة المجانية | السعر بعدها | التقييم |
|--------|-----------------|-------------|----------|
| **Agora** ⭐ | **10,000 دقيقة/شهر** | $0.99/1000 دقيقة | ⭐⭐⭐⭐⭐ |
| Zego Cloud | 10,000 دقيقة (لمرة واحدة) | $1.99/1000 دقيقة | ⭐⭐⭐ |
| Twilio | 1,000 دقيقة/شهر | $2.00/1000 دقيقة | ⭐⭐⭐⭐ |

**Agora هو الأفضل:**
- ✅ 10,000 دقيقة مجانية **كل شهر** (ليس لمرة واحدة)
- ✅ جودة فيديو ممتازة حتى في الإنترنت الضعيف
- ✅ SDK قوي ومستقر
- ✅ مستخدم من قبل كلوب هاوس، منصات التعليم، إلخ

---

## 🔑 الخطوة 1: الحصول على Agora App ID

### 1.1 إنشاء حساب
1. اذهب إلى [Agora Console](https://console.agora.io/)
2. سجل حساب جديد (مجاني بالكامل)
3. سجل الدخول

### 1.2 إنشاء مشروع
1. من Dashboard، اضغط **"Create Project"**
2. ادخل اسم المشروع (مثلاً: `MyApp Video`)
3. اختر **"Secured mode: APP ID + Token"** للأمان
4. اضغط **Submit**

### 1.3 الحصول على App ID
1. ستجد **App ID** مباشرة في صفحة المشروع
2. انسخه (يبدو مثل: `a1b2c3d4e5f6g7h8i9j0`)

📝 **احفظ App ID في مكان آمن!**

### 1.4 توليد Token (للاختبار)
للتطوير والاختبار فقط:
1. اضغط على **"Generate temp RTC token"**
2. ادخل اسم Channel (مثل: `test_channel`)
3. انسخ الـ Token المؤقت (يعمل لمدة 24 ساعة)

> **ملاحظة:** للإنتاج، ستحتاج Token Server (سنشرح لاحقاً)

---

## 🔥 الخطوة 2: الحصول على مفتاح FCM

### 2.1 فتح Firebase Console
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك الحالي

### 2.2 الحصول على Server Key
1. اضغط على **⚙️ Project Settings**
2. اذهب إلى تبويب **Cloud Messaging**
3. في قسم **"Cloud Messaging API (Legacy)"**:
   - إذا معطّل، اضغط على النقاط الثلاث → **"Manage API in Google Cloud Console"**
   - فعّل **"Cloud Messaging API"**
4. انسخ **Server Key**

📝 **احفظ Server Key بأمان**

---

## 💻 الخطوة 3: تكوين الكود

### 3.1 تحديث `golive.dart`

افتح الملف:
```
lib/E-commerce_project/features/mainprog/screen/catogriesScreens/golive.dart
```

**تأكد من إعداد `NotificationService`:**
نستخدم الآن **HTTP v1 API** للإشعارات، وهو أكثر أماناً وموثوقية.
تأكد من وجود ملف `service_account.json` (بيانات الاعتماد) في ملف `.env`، حيث يقوم `NotificationService` بقراءته لتوليد Access Token تلقائيًا.

**استبدل السطر 364 (Agora App ID):**
```dart
// BEFORE:
static const String agoraAppId = '2d65dc58bba24b468ea290a7e59c663e';

// AFTER (ضع App ID الفعلي من Agora إذا تغير):
static const String agoraAppId = 'your_actual_app_id_here';
```

**استبدل السطر 500 (Firebase Project ID):**
```dart
// تأكد من وضع Project ID الصحيح لمشروعك في Firebase
static const String firebaseProjectId = 'crccproject-98fb0';
```

---

## 📱 الخطوة 4: إعدادات Android

### 4.1 تحديث AndroidManifest.xml

افتح: `android/app/src/main/AndroidManifest.xml`

**أضف قبل `<application>`:**
```xml
<!-- Permissions for Agora -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

### 4.2 تحديث build.gradle

افتح: `android/app/build.gradle`

تأكد من:
```gradle
android {
    compileSdkVersion 34  // أو أحدث

    defaultConfig {
        minSdkVersion 24  // مهم لـ Agora
        targetSdkVersion 34
    }
}
```

---

## 🍎 الخطوة 5: إعدادات iOS

### 5.1 تحديث Info.plist

افتح: `ios/Runner/Info.plist`

**أضف قبل `</dict>`:**
```xml
<key>NSCameraUsageDescription</key>
<string>نحتاج للوصول للكاميرا لمكالمات الفيديو</string>
<key>NSMicrophoneUsageDescription</key>
<string>نحتاج للوصول للميكروفون لمكالمات الفيديو</string>
```

### 5.2 تحديث Podfile

افتح: `ios/Podfile`

تأكد من:
```ruby
platform :ios, '12.0'  # أو أحدث
```

---

## 📞 الخطوة 6: معالجة الإشعارات الواردة

أضف هذا الكود في ملف معالج الإشعارات (مثلاً `main.dart`):

```dart
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/agora_video_call_screen.dart';

// في FirebaseMessaging.onMessage.listen
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['type'] == 'video_call') {
    final channelName = message.data['channel_name'];
    final callerEmail = message.data['caller_email'];

    // Show incoming call dialog
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: const Text(
          'مكالمة فيديو واردة',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, color: Colors.white, size: 60),
            const SizedBox(height: 16),
            Text(
              'من: $callerEmail',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('رفض', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Join the call
              Get.to(() => AgoraVideoCallScreen(
                channelName: channelName,
                userEmail: message.data['receiver_email'],
                isReceiver: true,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('قبول'),
          ),
        ],
      ),
    );
  }
});
```

---

## ✅ الخطوة 7: التحقق من الإعداد

### اختبار التطبيق:

1. **نفّذ الأوامر:**
   ```bash
   flutter pub get
   flutter clean
   flutter run
   ```

2. **اختبر على جهازين:**
   - سجل دخول بحسابات مختلفة
   - افتح شاشة GoLive
   - اضغط زر "اتصال"

3. **تأكد من:**
   - ✅ طلب صلاحيات الكاميرا والميكروفون
   - ✅ فتح شاشة المكالمة
   - ✅ وصول الإشعار للجهاز الآخر
   - ✅ ظهور الفيديو المحلي (preview)
   - ✅ ظهور الفيديو البعيد عند قبول المكالمة
   - ✅ عمل أزرار التحكم (مايك، كاميرا، إنهاء، تبديل)

---

## 🔐 الخطوة 8: Token Server (للإنتاج)

### لماذا نحتاج Token Server؟

- Token المؤقت من Console يعمل 24 ساعة فقط
- للأمان، لا تضع Token ثابت في الكود
- في الإنتاج، اطلب Token جديد من Backend

### إنشاء Token Server بسيط:

**مثال بـ Node.js:**
```javascript
const express = require('express');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

const app = express();
const APP_ID = 'your_app_id';
const APP_CERTIFICATE = 'your_app_certificate'; // من Agora Console

app.get('/rtc/:channel/:uid', (req, res) => {
  const channelName = req.params.channel;
  const uid = parseInt(req.params.uid);
  const role = RtcRole.PUBLISHER;
  const expireTime = 3600; // 1 hour

  const currentTime = Math.floor(Date.now() / 1000);
  const privilegeExpireTime = currentTime + expireTime;

  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    channelName,
    uid,
    role,
    privilegeExpireTime
  );

  res.json({ token });
});

app.listen(3000);
```

**استخدامه في Flutter:**
```dart
Future<String> fetchToken(String channelName) async {
  final response = await http.get(
    Uri.parse('https://your-server.com/rtc/$channelName/0'),
  );
  final data = json.decode(response.body);
  return data['token'];
}
```

---

## 🛠️ استكشاف الأخطاء

### مشكلة: "Permission denied"
**الحل:**
- تأكد من إضافة permissions في AndroidManifest.xml
- تأكد من إضافة NSCameraUsageDescription في Info.plist
- أعد تشغيل التطبيق

### مشكلة: "Invalid App ID"
**الحل:**
- تحقق من App ID في Console
- تأكد من عدم وجود مسافات في النسخ
- جرب مشروع جديد في Agora

### مشكلة: لا يظهر الفيديو البعيد
**الحل:**
- تأكد من اتصال الإنترنت
- تحقق من Channel Name (يجب أن يكون نفسه)
- راجع Agora logs في Console

### مشكلة: "Token expired"
**الحل:**
- استخدم Token جديد من Console
- أو أنشئ Token Server (للإنتاج)

---

## 💰 تتبع الاستخدام

### Dashboard Agora:
1. اذهب إلى [Agora Console](https://console.agora.io/)
2. اختر مشروعك
3. اضغط **"Usage"**
4. راجع:
   - عدد الدقائق المستخدمة
   - عدد المكالمات
   - الدقائق المتبقية المجانية

### نصائح لتوفير الدقائق:
- استخدم voice-only للمكالمات القصيرة
- اضبط video quality حسب الحاجة
- أغلق المكالمة عند الانتهاء

---

## 📚 مصادر إضافية

- [Agora Flutter Documentation](https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter)
- [Agora Token Server](https://docs.agora.io/en/video-calling/develop/authentication-workflow)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Permission Handler Package](https://pub.dev/packages/permission_handler)

---

## ⚡ الميزات المتاحة

الكود الحالي يدعم:
- ✅ مكالمات فيديو 1-to-1
- ✅ تبديل الكاميرا (أمامي/خلفي)
- ✅ كتم الصوت
- ✅ إيقاف الفيديو
- ✅ إشعارات المكالمات الواردة
- ✅ معاينة الفيديو المحلي
- ✅ واجهة مستخدم احترافية

---

**آخر تحديث:** 6 فبراير 2026
**الإصدار:** Agora RTC Engine 6.3.2
**الرخصة:** 10,000 دقيقة مجانية شهرياً
