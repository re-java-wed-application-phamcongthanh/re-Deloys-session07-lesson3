#!/bin/bash
# ==============================================================================
# Script: setup_spring_service.sh
# Mo ta: Tu dong tao user system, thu muc ung dung va install Systemd Service
# Khoa hoc: DevOps Fundamentals - Session 07 - Bai 3
# ==============================================================================

set -e

echo "=== [1/6] Kiem tra quyen root ==="
if [ "$EUID" -ne 0 ]; then
  echo "Loi: Vui long chay script duoi quyen root hoac dung sudo!"
  exit 1
fi

echo "=== [2/6] Tao user he thong spring-runner (No Shell Login) ==="
if id "spring-runner" &>/dev/null; then
    echo "User spring-runner da ton tai."
else
    useradd -r -s /sbin/nologin spring-runner
    echo "Da tao user he thong spring-runner (no-login)."
fi

echo "=== [3/6] Chuap bi thu muc /opt/spring-app va file jar ==="
mkdir -p /opt/spring-app
# Neu chua co file app.jar, tao gia lap file app.jar
if [ ! -f /opt/spring-app/app.jar ]; then
    echo "Creating dummy app.jar for testing..."
    touch /opt/spring-app/app.jar
fi

# Phan quyen so huu cho spring-runner
chown -R spring-runner:spring-runner /opt/spring-app
chmod 755 /opt/spring-app
chmod 644 /opt/spring-app/app.jar

echo "=== [4/6] Copy tệp tin spring-app.service vao /etc/systemd/system/ ==="
cp spring-app.service /etc/systemd/system/spring-app.service
chmod 644 /etc/systemd/system/spring-app.service

echo "=== [5/6] Daemon Reload va Enable Service ==="
systemctl daemon-reload
systemctl enable spring-app.service
systemctl restart spring-app.service || true

echo "=== [6/6] Kiem tra trang thai dich vu ==="
systemctl status spring-app.service --no-pager || true
echo ""
echo "Kiem tra port 8082:"
ss -tlnp | grep 8082 || echo "Port 8082 dang cho ung dung khoi chạy."

echo "================================================="
echo "CAU HINH SYSTEMD SERVICE HOAN THANH THANH CONG!"
echo "================================================="
