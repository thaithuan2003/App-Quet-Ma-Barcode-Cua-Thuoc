# Pharmacy Barcode Backend

Backend ASP.NET Core Web API cho app Flutter quet ma vach thuoc.

## Yeu cau

- .NET 8 SDK
- SQL Server Express hoac SQL Server Developer

## Chay local

1. Mo file `Pharmacy.Api/appsettings.Development.json`.
2. Kiem tra connection string:

```json
"DefaultConnection": "Server=localhost;Database=PharmacyBarcodeDb;Trusted_Connection=True;TrustServerCertificate=True"
```

3. Chay API:

```powershell
cd backend
dotnet restore
dotnet run --project Pharmacy.Api
```

API se tu tao database va seed du lieu demo bang `EnsureCreated`.

Swagger:

```text
http://localhost:5000/swagger
```

## Tai khoan demo

- `admin / admin123`
- `staff / staff123`

Role he thong chi con `Admin` va `Staff`. Neu database da tao tu ban cu, backend se tu khoa user `manager` khi khoi dong lai.

## Barcode demo

- `8938505974190` - Paracetamol 500mg
- `8938505974206` - Ibuprofen 200mg
- `8938505974213` - Amoxicillin 500mg

## Ghi chu migration

Ban dau dung `EnsureCreated` de de test khi chua co migration sinh bang CLI. Khi can nop ban hoan chinh, nen doi sang EF migration:

```powershell
dotnet ef migrations add InitialCreate --project Pharmacy.Infrastructure --startup-project Pharmacy.Api
dotnet ef database update --project Pharmacy.Infrastructure --startup-project Pharmacy.Api
```
