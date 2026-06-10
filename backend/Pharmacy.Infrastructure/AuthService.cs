using Microsoft.EntityFrameworkCore;
using Pharmacy.Application;

namespace Pharmacy.Infrastructure;

public sealed class AuthService(PharmacyDbContext db, ITokenProvider tokenProvider) : IAuthService
{
    public async Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken)
    {
        var user = await db.Users
            .Include(x => x.UserRoles).ThenInclude(x => x.Role)
            .FirstOrDefaultAsync(x => x.Username == request.Username && x.IsActive, cancellationToken);

        if (user is null || !PasswordHasher.Verify(request.Password, user.PasswordHash))
        {
            return null;
        }

        var roles = user.UserRoles.Select(x => x.Role.Name.ToString()).ToList();
        var token = tokenProvider.CreateToken(user.Id, user.Username, user.FullName, roles);
        return new LoginResponse(token, user.FullName, user.Username, roles);
    }
}
