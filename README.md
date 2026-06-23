# CNPM_BDTT - Hệ thống nhà thuốc quét mã vạch

Project gồm ứng dụng Flutter cho nhân viên nhà thuốc và backend ASP.NET Core Web API. Hệ thống hỗ trợ đăng nhập, quét mã vạch thuốc, tra cứu thông tin thuốc, kiểm tra hạn sử dụng, quản lý tồn kho, lô thuốc, lịch sử quét, cảnh báo và báo cáo thống kê.

## 1. Môi trường cài đặt

Cần cài đặt các công cụ sau trước khi chạy project:

- Visual Studio 2022
- .NET 8 SDK
- SQL Server LocalDB hoặc SQL Server Express/Developer
- Flutter SDK
- Android Studio hoặc Android Emulator
- Git

Kiểm tra phiên bản .NET:

```powershell
dotnet --version
```

Kiểm tra Flutter:

```powershell
flutter doctor
```

## 2. Kiến trúc hệ thống

Project được chia thành 2 phần chính:

```text
cnpm_bdtt/
|-- lib/                         Ứng dụng Flutter
|-- backend/                     Backend ASP.NET Core Web API
|   |-- Pharmacy.Api/            API controller, JWT, Swagger, cấu hình chạy
|   |-- Pharmacy.Application/    DTO và interface service
|   |-- Pharmacy.Domain/         Entity và enum nghiệp vụ
|   |-- Pharmacy.Infrastructure/ EF Core, DbContext, service, seed dữ liệu
|-- pubspec.yaml                 Cấu hình Flutter
|-- README.md                    Hướng dẫn cài đặt và chạy project
```

Mô hình hoạt động:

```text
Flutter App
    |
    | Gọi HTTP API
    v
ASP.NET Core Web API
    |
    | Entity Framework Core
    v
SQL Server LocalDB - PharmacyBarcodeDb
```

Công nghệ sử dụng:

- Frontend/mobile: Flutter
- Backend: ASP.NET Core Web API .NET 8
- Database: SQL Server LocalDB
- ORM: Entity Framework Core
- Xác thực: JWT Bearer Token
- Tài liệu API: Swagger

## 3. Cấu hình database

Backend đang dùng SQL Server LocalDB với database tên:

```text
PharmacyBarcodeDb
```

Connection string nằm trong file:

```text
backend/Pharmacy.Api/appsettings.json
backend/Pharmacy.Api/appsettings.Development.json
```

Nội dung mặc định:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=PharmacyBarcodeDb;Trusted_Connection=True;TrustServerCertificate=True"
  }
}
```

Nếu máy không dùng LocalDB, có thể đổi `Server=(localdb)\\MSSQLLocalDB` thành tên SQL Server đang sử dụng, ví dụ:

```text
Server=localhost;Database=PharmacyBarcodeDb;Trusted_Connection=True;TrustServerCertificate=True
```

## 4. Cách tạo database

Project hiện tại dùng `EnsureCreated` để tự tạo database khi backend khởi động. Không cần tạo database thủ công nếu LocalDB đã cài đặt sẵn.

Các bước tạo database:

1. Mở terminal tại thư mục project.

2. Di chuyển vào thư mục backend:

```powershell
cd backend
```

3. Restore package:

```powershell
dotnet restore
```

4. Chạy API:

```powershell
dotnet run --project Pharmacy.Api
```

5. Khi API chạy lần đầu, hệ thống sẽ tự tạo database:

```text
PharmacyBarcodeDb
```

Đồng thời seed sẵn dữ liệu demo:

- Role: Admin, Staff
- Tài khoản đăng nhập demo
- Thuốc demo
- Lô thuốc demo
- Tồn kho demo
- Dữ liệu cảnh báo và lịch sử phục vụ kiểm thử

Có thể kiểm tra database bằng SQL Server Object Explorer trong Visual Studio 2022:

```text
SQL Server Object Explorer
-> (localdb)\MSSQLLocalDB
-> Databases
-> PharmacyBarcodeDb
```

## 5. Tài khoản đăng nhập demo

Sử dụng các tài khoản sau để đăng nhập hệ thống:

| Vai trò | ID đăng nhập | Mật khẩu |
|---|---|---|
| Admin | admin | admin123 |
| Staff | staff | staff123 |

Quyền của từng tài khoản:

- Admin: có quyền truy cập chức năng quản trị tài khoản nhân viên, tạo/sửa/xóa/khóa/mở khóa user.
- Staff: sử dụng các chức năng nghiệp vụ thông thường, không thấy menu quản trị.

## 6. Hướng dẫn cài đặt và triển khai

### 6.1. Chạy backend API

Mở terminal tại thư mục project:

```powershell
cd backend
dotnet restore
dotnet run --project Pharmacy.Api
```

Sau khi chạy thành công, API mặc định hoạt động tại:

```text
http://localhost:5000
https://localhost:5001
```

Mở Swagger để kiểm tra API:

```text
http://localhost:5000/swagger
```

### 6.2. Chạy ứng dụng Flutter

Mở terminal khác tại thư mục gốc project:

```powershell
flutter pub get
flutter run
```

Mặc định app Flutter gọi API tại:

```text
http://10.0.2.2:5000/api
```

Địa chỉ `10.0.2.2` dùng cho Android Emulator để truy cập `localhost` của máy tính.

Nếu chạy trên điện thoại thật, cần truyền IP máy tính đang chạy backend:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:5000/api
```

Ví dụ:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api
```

## 7. Cách kiểm tra chức năng

1. Chạy backend API và mở Swagger:

```text
http://localhost:5000/swagger
```

2. Chạy ứng dụng Flutter.

3. Đăng nhập bằng tài khoản demo:

```text
admin / admin123
```

hoặc:

```text
staff / staff123
```

4. Kiểm tra các chức năng chính:

- Đăng nhập hệ thống
- Tra cứu thông tin thuốc
- Quét mã vạch thuốc
- Kiểm tra hạn sử dụng và lô thuốc
- Quản lý tồn kho
- Xem lịch sử quét
- Xem cảnh báo
- Xem báo cáo thống kê
- Admin quản lý tài khoản nhân viên

Barcode demo để kiểm tra:

| Barcode | Tên thuốc |
|---|---|
| 8938505974190 | Paracetamol 500mg |
| 8938505974206 | Ibuprofen 200mg |
| 8938505974213 | Amoxicillin 500mg |

## 8. Ghi chú cho Visual Studio 2022

Có thể mở backend bằng Visual Studio 2022:

```text
backend/Pharmacy.sln
```

Chọn project startup:

```text
Pharmacy.Api
```

Sau đó bấm `F5` hoặc `Ctrl + F5` để chạy API.

Nếu database cũ bị lỗi do thay đổi cấu trúc bảng, có thể xóa database `PharmacyBarcodeDb` trong SQL Server Object Explorer, sau đó chạy lại backend để hệ thống tạo database mới.
