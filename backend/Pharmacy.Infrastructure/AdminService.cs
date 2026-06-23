using Microsoft.EntityFrameworkCore;
using Pharmacy.Application;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

public sealed class AdminService(PharmacyDbContext db) : IAdminService
{
    public async Task<IReadOnlyList<UserDto>> GetUsersAsync(CancellationToken cancellationToken)
    {
        var users = await db.Users
            .Include(x => x.UserRoles).ThenInclude(x => x.Role)
            .OrderBy(x => x.Username)
            .ToListAsync(cancellationToken);

        return users.Select(ToDto).ToList();
    }

    public async Task<UserDto> CreateStaffAsync(CreateStaffRequest request, CancellationToken cancellationToken)
    {
        var username = request.Username.Trim();
        if (username.Length < 3)
        {
            throw new InvalidOperationException("Tên đăng nhập phải có ít nhất 3 ký tự.");
        }

        if (request.Password.Length < 6)
        {
            throw new InvalidOperationException("Mật khẩu phải có ít nhất 6 ký tự.");
        }

        if (await db.Users.AnyAsync(x => x.Username == username, cancellationToken))
        {
            throw new InvalidOperationException("Tên đăng nhập đã tồn tại.");
        }

        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            throw new InvalidOperationException("Họ tên nhân viên không được để trống.");
        }

        var staffRole = await db.Roles.FirstAsync(x => x.Name == UserRoleName.Staff, cancellationToken);
        var user = new User
        {
            FullName = request.FullName.Trim(),
            Username = username,
            PasswordHash = PasswordHasher.Hash(request.Password),
            UserRoles = [new UserRole { RoleId = staffRole.Id }]
        };

        db.Users.Add(user);
        await db.SaveChangesAsync(cancellationToken);

        return ToDto(await db.Users
            .Include(x => x.UserRoles).ThenInclude(x => x.Role)
            .FirstAsync(x => x.Id == user.Id, cancellationToken));
    }

    public async Task<UserDto> UpdateStaffAsync(int userId, UpdateStaffRequest request, CancellationToken cancellationToken)
    {
        var user = await db.Users
            .Include(x => x.UserRoles).ThenInclude(x => x.Role)
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy tài khoản.");

        if (user.UserRoles.Any(x => x.Role.Name == UserRoleName.Admin))
        {
            throw new InvalidOperationException("Không sửa tài khoản admin tại màn hình nhân viên.");
        }

        var username = request.Username.Trim();
        if (username.Length < 3)
        {
            throw new InvalidOperationException("Tên đăng nhập phải có ít nhất 3 ký tự.");
        }

        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            throw new InvalidOperationException("Họ tên nhân viên không được để trống.");
        }

        if (await db.Users.AnyAsync(x => x.Id != userId && x.Username == username, cancellationToken))
        {
            throw new InvalidOperationException("Tên đăng nhập đã tồn tại.");
        }

        if (!string.IsNullOrWhiteSpace(request.Password))
        {
            if (request.Password.Length < 6)
            {
                throw new InvalidOperationException("Mật khẩu phải có ít nhất 6 ký tự.");
            }

            user.PasswordHash = PasswordHasher.Hash(request.Password);
        }

        user.FullName = request.FullName.Trim();
        user.Username = username;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(cancellationToken);

        return ToDto(user);
    }

    public async Task<UserDto> UpdateUserStatusAsync(int userId, UpdateUserStatusRequest request, CancellationToken cancellationToken)
    {
        var user = await db.Users
            .Include(x => x.UserRoles).ThenInclude(x => x.Role)
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy tài khoản.");

        if (user.Username == "admin" && !request.IsActive)
        {
            throw new InvalidOperationException("Không được khóa tài khoản admin mặc định.");
        }

        user.IsActive = request.IsActive;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(cancellationToken);
        return ToDto(user);
    }

    public async Task DeleteStaffAsync(int userId, CancellationToken cancellationToken)
    {
        var user = await db.Users
            .Include(x => x.UserRoles).ThenInclude(x => x.Role)
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy tài khoản.");

        if (user.UserRoles.Any(x => x.Role.Name == UserRoleName.Admin))
        {
            throw new InvalidOperationException("Không được xóa tài khoản admin.");
        }

        var hasRelatedData =
            await db.ScanHistories.AnyAsync(x => x.UserId == userId, cancellationToken)
            || await db.InventoryTransactions.AnyAsync(x => x.UserId == userId, cancellationToken)
            || await db.VerificationLogs.AnyAsync(x => x.UserId == userId, cancellationToken)
            || await db.DispensingChecks.AnyAsync(x => x.UserId == userId, cancellationToken);

        if (hasRelatedData)
        {
            user.IsActive = false;
            user.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            db.Set<UserRole>().RemoveRange(user.UserRoles);
            db.Users.Remove(user);
        }

        await db.SaveChangesAsync(cancellationToken);
    }

    private static UserDto ToDto(User user)
    {
        return new UserDto(
            user.Id,
            user.FullName,
            user.Username,
            user.IsActive,
            user.UserRoles.Select(x => x.Role.Name.ToString()).ToList());
    }
}
