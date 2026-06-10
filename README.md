# cnpm_bdtt

Flutter Android app cho nhan vien nha thuoc quet ma vach, tra cuu thuoc, kiem tra han su dung, ton kho, lo thuoc, lich su quet, xac thuc noi bo, canh bao va bao cao thong ke.

## Kien truc

- `lib/`: Flutter app, tach theo feature.
- `backend/`: ASP.NET Core Web API.
- Database: SQL Server Express/Developer qua backend API.
- AI/web search: chua tich hop trong ban nay.

## Chay backend

```powershell
cd backend
dotnet restore
dotnet run --project Pharmacy.Api
```

Swagger:

```text
http://localhost:5000/swagger
```

## Chay Flutter

```powershell
flutter pub get
flutter run
```

Mac dinh app goi API:

```text
http://10.0.2.2:5000/api
```

Neu chay tren thiet bi that, truyen IP may tinh:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:5000/api
```

## Tai khoan demo

- `admin / admin123`
- `staff / staff123`

Admin co them menu `Quan tri` de tao, sua, xoa va khoa/mo tai khoan nhan vien. Staff khong thay menu nay.

## Barcode demo

- `8938505974190`
- `8938505974206`
- `8938505974213`
