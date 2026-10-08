# Báo Cáo Bài 3: Thiết lập Cơ sở dữ liệu và Tự cấu hình dịch vụ Systemd cho Spring Boot

## 🎯 1. Mục Tiêu
- Thực hành khởi tạo cơ sở dữ liệu MySQL (`springboot_db`) và phân quyền người dùng bảo mật (`spring-admin`).
- Tự thiết kế và viết tệp tin cấu hình dịch vụ Systemd (`spring-app.service`) từ đầu để quản lý tiến trình ứng dụng Spring Boot.
- Đảm bảo ứng dụng chạy tự động dưới quyền một tài khoản hệ thống giới hạn (**non-root** user `spring-runner`) với tính năng tự động khởi động lại khi crash (`Restart=on-failure`, `RestartSec=10`).

---

## 📋 2. Quy Trình Thực Hiện (Step-by-Step Guide)

### Bước 1: Khoảng tạo Cơ sở dữ liệu MySQL & Phân quyền User
Đăng nhập vào MySQL Console với quyền `root`:
```bash
sudo mysql -u root -p
```
Thực thi các lệnh khởi tạo CSDL và User:
```sql
-- 1. Tạo Database springboot_db
CREATE DATABASE IF NOT EXISTS springboot_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. Tạo User spring-admin với mật khẩu bảo mật
CREATE USER IF NOT EXISTS 'spring-admin'@'localhost' IDENTIFIED BY 'SpringSecure@123';

-- 3. Cấp toàn quyền trên database springboot_db
GRANT ALL PRIVILEGES ON springboot_db.* TO 'spring-admin'@'localhost';

-- 4. Làm mới bảng phân quyền
FLUSH PRIVILEGES;
```

---

### Bước 2: Khởi tạo User Hệ thống Linux `spring-runner`
Tạo người dùng hệ thống không có quyền đăng nhập shell (`no-login shell`) nhằm tăng cường bảo mật:
```bash
sudo useradd -r -s /sbin/nologin spring-runner
```
Chuẩn bị thư mục chứa ứng dụng và phân quyền:
```bash
sudo mkdir -p /opt/spring-app
sudo chown -R spring-runner:spring-runner /opt/spring-app
```

---

### Bước 3: Thiết kế tệp tin Systemd Service (`/etc/systemd/system/spring-app.service`)
Tạo tệp tin `/etc/systemd/system/spring-app.service` với nội dung cấu hình chi tiết:

```ini
[Unit]
Description=Spring Boot Application Service
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=spring-runner
Group=spring-runner
WorkingDirectory=/opt/spring-app
ExecStart=/usr/bin/java -jar /opt/spring-app/app.jar
SuccessExitStatus=143
Restart=on-failure
RestartSec=10
SyslogIdentifier=spring-app

# Cross-cutting environment configuration
Environment="PORT=8082"
Environment="SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/springboot_db?useSSL=false&serverTimezone=UTC"
Environment="SPRING_DATASOURCE_USERNAME=spring-admin"
Environment="SPRING_DATASOURCE_PASSWORD=SpringSecure@123"

# Security Restrictions
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

---

### Bước 4: Nạp lại Systemd Daemon và Khởi động Dịch vụ
```bash
# Nạp lại cấu hình daemon sau khi sửa/tạo tệp service
sudo systemctl daemon-reload

# Khởi động dịch vụ spring-app
sudo systemctl start spring-app.service

# Cấu hình tự động khởi động cùng hệ thống khi boot
sudo systemctl enable spring-app.service
```

---

## ✅ 3. Kết Quả Kiểm Tra & Xác Minh (Verification)

### 3.1. Kiểm tra trạng thái dịch vụ Systemd:
```bash
sudo systemctl status spring-app.service
```

**Output mẫu hiển thị:**
```text
● spring-app.service - Spring Boot Application Service
     Loaded: loaded (/etc/systemd/system/spring-app.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2026-10-08 07:20:18 UTC; 5min ago
   Main PID: 14520 (java)
      Tasks: 28 (limit: 4571)
     Memory: 185.4M
        CPU: 4.120s
     CGroup: /system.slice/spring-app.service
             └─14520 /usr/bin/java -jar /opt/spring-app/app.jar
```
> ✅ **Xác nhận**: Dịch vụ hiển thị `active (running)`, quản lý bởi tiến trình Java PID `14520`.

---

### 3.2. Kiểm tra cổng lắng nghe của ứng dụng:
```bash
ss -tlnp | grep 8082
```

**Output mẫu hiển thị:**
```text
LISTEN 0      100        *:8082            *:*    users:(("java",pid=14520,fd=14))
```
> ✅ **Xác nhận**: Cổng `8082` đang được lắng nghe bởi tiến trình Java chạy dưới quyền `spring-runner`.

---

## 🔒 4. Phân Tích Kỹ Thuật & Bảo Mật

1. **Chạy ứng dụng dưới quyền Non-Root (`spring-runner`)**:
   - Ngăn chặn nguy cơ tin tặc chiếm quyền kiểm soát toàn bộ máy chủ (`root`) nếu ứng dụng Java bị lỗi bảo mật (RCE / Log4j vulnerability).
   - User `spring-runner` có `/sbin/nologin`, không ai có thể dùng user này để SSH hoặc login vào Terminal.
2. **Cơ chế Tự phục hồi (`Restart=on-failure`, `RestartSec=10`)**:
   - Đảm bảo tính khả dụng cao (High Availability). Nếu ứng dụng bị Out-Of-Memory (OOM) hoặc Crash bất ngờ, Systemd sẽ tự động khởi động lại dịch vụ sau 10 giây.
3. **Phân quyền CSDL (`spring-admin`)**:
   - Tài khoản `spring-admin` chỉ có quyền trên `springboot_db`, không có quyền can thiệp vào các database hệ thống (`mysql`, `information_schema`).
