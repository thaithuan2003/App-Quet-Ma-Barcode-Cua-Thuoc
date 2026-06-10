using Microsoft.EntityFrameworkCore;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

public static class DatabaseBootstrapper
{
    public static async Task EnsureSchemaAndDefaultsAsync(PharmacyDbContext db, CancellationToken cancellationToken = default)
    {
        await db.Database.EnsureCreatedAsync(cancellationToken);
        await db.Database.ExecuteSqlRawAsync("""
IF OBJECT_ID(N'[UserRole]', N'U') IS NOT NULL AND OBJECT_ID(N'[Roles]', N'U') IS NOT NULL
BEGIN
    DELETE ur
    FROM [UserRole] ur
    INNER JOIN [Roles] r ON r.[Id] = ur.[RoleId]
    WHERE r.[Name] NOT IN (0, 1);

    DELETE FROM [Roles]
    WHERE [Name] NOT IN (0, 1);
END
IF OBJECT_ID(N'[Customers]', N'U') IS NOT NULL
BEGIN
    DROP TABLE [Customers];
END
""", cancellationToken);

        await EnsureRoleAsync(db, UserRoleName.Admin, cancellationToken);
        await EnsureRoleAsync(db, UserRoleName.Staff, cancellationToken);
        await EnsureDefaultUserRolesAsync(db, cancellationToken);

        var manager = await db.Users.FirstOrDefaultAsync(x => x.Username == "manager", cancellationToken);
        if (manager is not null)
        {
            var managerRoles = await db.Set<UserRole>().Where(x => x.UserId == manager.Id).ToListAsync(cancellationToken);
            db.Set<UserRole>().RemoveRange(managerRoles);

            var managerHasRelatedData =
                await db.ScanHistories.AnyAsync(x => x.UserId == manager.Id, cancellationToken)
                || await db.InventoryTransactions.AnyAsync(x => x.UserId == manager.Id, cancellationToken)
                || await db.VerificationLogs.AnyAsync(x => x.UserId == manager.Id, cancellationToken)
                || await db.DispensingChecks.AnyAsync(x => x.UserId == manager.Id, cancellationToken);

            if (managerHasRelatedData)
            {
                manager.IsActive = false;
                manager.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                db.Users.Remove(manager);
            }
        }

        await db.SaveChangesAsync(cancellationToken);
    }

    private static async Task EnsureRoleAsync(PharmacyDbContext db, UserRoleName roleName, CancellationToken cancellationToken)
    {
        if (!await db.Roles.AnyAsync(x => x.Name == roleName, cancellationToken))
        {
            db.Roles.Add(new Role { Name = roleName });
            await db.SaveChangesAsync(cancellationToken);
        }
    }

    private static async Task EnsureDefaultUserRolesAsync(PharmacyDbContext db, CancellationToken cancellationToken)
    {
        var admin = await db.Users.FirstOrDefaultAsync(x => x.Username == "admin", cancellationToken);
        var staff = await db.Users.FirstOrDefaultAsync(x => x.Username == "staff", cancellationToken);
        var adminRole = await db.Roles.FirstAsync(x => x.Name == UserRoleName.Admin, cancellationToken);
        var staffRole = await db.Roles.FirstAsync(x => x.Name == UserRoleName.Staff, cancellationToken);

        if (admin is not null && !await db.Set<UserRole>().AnyAsync(x => x.UserId == admin.Id && x.RoleId == adminRole.Id, cancellationToken))
        {
            db.Set<UserRole>().Add(new UserRole { UserId = admin.Id, RoleId = adminRole.Id });
        }

        if (staff is not null && !await db.Set<UserRole>().AnyAsync(x => x.UserId == staff.Id && x.RoleId == staffRole.Id, cancellationToken))
        {
            db.Set<UserRole>().Add(new UserRole { UserId = staff.Id, RoleId = staffRole.Id });
        }
    }
}
