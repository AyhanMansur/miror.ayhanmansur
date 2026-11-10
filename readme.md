<div align="center">

# 🐧 Linux Scripts Hub

**مجموعه‌ی یکپارچه‌ی اسکریپت‌های نصب و راه‌اندازی لینوکس — سریع، امن، و همیشه در دسترس**

[![Mirror](https://img.shields.io/badge/mirror-active-brightgreen)](https://<username>.github.io/)
[![Files](https://img.shields.io/badge/files-18-blue)](https://<username>.github.io/)
[![License](https://img.shields.io/badge/license-mixed-lightgrey)](https://<username>.github.io/)

</div>

---

## ✨ چرا این مخزن؟

نصب سریع ابزارهای لینوکسی همیشه ساده نیست: لینک‌های پراکنده، اسکریپت‌های قدیمی، و دانلود کند از منابع مختلف. **Linux Scripts Hub** این مشکل را حل می‌کند:

- ⚡ **دسترسی سریع** — همه‌ی اسکریپت‌ها در یک مکان، با CDN GitHub Pages
- 🔐 **تأیید شده** — هر فایل با SHA-256 قابل بررسی است
- 🔄 **به‌روز** — همگام با مخازن اصلی
- 📦 **بدون وابستگی** — فقط `curl` و `bash` لازم دارید

---

## 🚀 شروع سریع

هر اسکریپت را با یک دستور دریافت و اجرا کنید:

```bash
# دریافت
curl -fsSL https://<username>.github.io/backhaul.sh -o backhaul.sh

# بررسی (پیشنهادی)
less backhaul.sh

# اجرا
chmod +x backhaul.sh
sudo ./backhaul.sh
```

---

## 📦 محصولات موجود

### 🔗 تونل و Reverse Proxy
| اسکریپت | کاربرد |
|---|---|
| `backhaul.sh` | تونل معکوس Backhaul |
| `rathole.sh` / `rathole_v2.sh` | تونل Rathole (v1 و v2) |
| `haproxy.sh` | HAProxy برای Load Balancing و Port Forwarding |

### 💬 پیام‌رسان و ارتباطات
| اسکریپت | کاربرد |
|---|---|
| `matrix-install.sh` | سرور Matrix Synapse |
| `chatto-install.sh` | چت‌سرور Chatto |
| `jitsi-meet-install.sh` | کنفرانس ویدیویی Jitsi Meet |

### 🌐 شبکه و Mesh
| اسکریپت | کاربرد |
|---|---|
| `easymesh.sh` / `easymesh_v2.sh` | شبکه P2P Easy-Mesh |

### 📊 پنل و مدیریت
| اسکریپت | کاربرد |
|---|---|
| `xui-install.sh` / `xui29-install.sh` | پنل X-UI |
| `rebecca-binary.sh` / `rebecca-node-binary.sh` | پنل Rebecca و Node |
| `pasarguard-panel-install.sh` / `pasarguard-node-install.sh` | پنل و Node PasarGuard |

### 📁 اشتراک فایل
| اسکریپت | کاربرد |
|---|---|
| `pingvin-share-x-install.sh` | اشتراک فایل Pingvin Share X |

---

## 🛡️ امنیت و تأیید

همه‌ی فایل‌ها با SHA-256 قابل بررسی هستند:

```bash
curl -fsSL https://<username>.github.io/SHA256SUMS -o SHA256SUMS
sha256sum -c SHA256SUMS
```

خروجی `OK` برای همه‌ی خطوط = فایل‌ها سالم و دست‌نخورده هستند.

> ⚠️ **همیشه قبل از اجرا، محتوای اسکریپت را بخوانید.** هیچ اسکریپتی را بدون بررسی اجرا نکنید.

---

## 🗂️ ساختار مخزن

```
.
├── index.html          # لیست فایل‌ها (GitHub Pages)
├── SHA256SUMS          # هش تمام فایل‌ها
├── README.md           # همین فایل
└── *.sh                # اسکریپت‌ها
```

---

## 🤝 مشارکت

اگر اسکریپت جدیدی دارید یا نسخه‌ی به‌روزتری از یکی از فایل‌ها پیدا کردید:

1. Fork کنید
2. فایل را اضافه/به‌روز کنید
3. `SHA256SUMS` را دوباره بسازید:
   ```bash
   sha256sum *.sh > SHA256SUMS
   ```
4. یک `index.html` را با `<tr>` جدید به‌روز کنید
5. Pull Request بفرستید

---

## 📄 لایسنس

هر اسکریپت تابع لایسنس مخزن اصلی خودش است. برای جزئیات به مخزن منبع (ستون «منبع» در جدول‌ها) مراجعه کنید.

---

<div align="center">

**ساخته شده با ❤️ برای جامعه‌ی لینوکس**

[🌐 مشاهده Mirror](https://<username>.github.io/)

</div>
```

---

**نکته:** جای `<username>` را با نام کاربری GitHub خودتان عوض کنید. اگر پوشه‌ی `files/` دارید، مسیرها را در دستورات `curl` به `files/backhaul.sh` تغییر دهید.
