# Bài 4: Thiết lập Custom Network và Named Volume bằng Docker CLI

## 1. Mục tiêu
- Tạo custom bridge network `app-net`.
- Tạo named volume `db-data`.
- Chạy PostgreSQL trong container `db-server`.
- Chạy backend Node.js trong container `app-container`.
- Kết nối backend tới database qua hostname `db-server`.
- Kiểm tra dữ liệu tồn tại sau khi xóa và tạo lại container PostgreSQL.

## 2. Công nghệ sử dụng
- Docker Desktop 4.87.0
- Docker Engine 29.7.2
- Node.js 18 Alpine
- Express 4.21.2
- PostgreSQL 15 Alpine
- PostgreSQL client library `pg` 8.16.3

## 3. Cấu trúc thư mục
```text
ex4/
├── Dockerfile
├── commands.sh
├── package.json
├── server.js
└── README.md
```

## 4. Thiết lập network và volume
File `commands.sh` tạo custom bridge network `app-net`, named volume `db-data`, container PostgreSQL `db-server` và container backend `app-container`.

Volume `db-data` được gắn vào `/var/lib/postgresql/data`. Hai container cùng tham gia network `app-net`, do đó backend có thể sử dụng hostname `db-server` để kết nối database.

## 5. Kiểm tra network
Lệnh:
```bash
docker network inspect app-net
docker exec -it app-container ping -c 2 db-server
```

Kết quả thực tế: ping thành công, 2 gói tin gửi và nhận, 0% packet loss. Network sử dụng driver `bridge`.

## 6. Kiểm tra volume
Lệnh:
```bash
docker volume inspect db-data
```

Kết quả: volume `db-data` tồn tại với driver `local`.

## 7. Kiểm tra backend và database
Lệnh:
```bash
curl http://localhost:3000/api/health
```

Kết quả thực tế:
```json
{
  "status": "UP",
  "database": "appdb",
  "serverTime": "2026-10-11T09:40:00.759Z"
}
```

Kết quả xác nhận backend đang hoạt động và kết nối được tới PostgreSQL.

## 8. Kiểm thử tính bền vững dữ liệu

### 8.1. Tạo bảng và dữ liệu kiểm thử
```bash
docker exec db-server psql -U appuser -d appdb -c "CREATE TABLE IF NOT EXISTS persistence_test (id SERIAL PRIMARY KEY, content TEXT NOT NULL); INSERT INTO persistence_test (content) VALUES ('Volume persistence works');"
docker exec db-server psql -U appuser -d appdb -c "SELECT * FROM persistence_test;"
```

### 8.2. Xóa container PostgreSQL
```bash
docker rm -f db-server
```

### 8.3. Tạo lại container với cùng named volume
```bash
docker run -d \
  --name db-server \
  --network app-net \
  -e POSTGRES_DB=appdb \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=apppass \
  -v db-data:/var/lib/postgresql/data \
  postgres:15-alpine
```

Chờ PostgreSQL sẵn sàng:
```bash
until docker exec db-server pg_isready -U appuser -d appdb; do sleep 2; done
```

Truy vấn lại dữ liệu:
```bash
docker exec db-server psql -U appuser -d appdb -c "SELECT * FROM persistence_test;"
```

### 8.4. Kết quả
Sau khi xóa và tạo lại container `db-server`, các bản ghi trong bảng `persistence_test` vẫn tồn tại. Điều này chứng minh dữ liệu được lưu trong named volume `db-data`, không phụ thuộc vào vòng đời của container.

## 9. Kết luận
Bài thực hành đã thiết lập thành công custom bridge network, named volume, kết nối backend với PostgreSQL bằng hostname container, kiểm tra API và xác minh dữ liệu được bảo toàn sau khi tạo lại container.
