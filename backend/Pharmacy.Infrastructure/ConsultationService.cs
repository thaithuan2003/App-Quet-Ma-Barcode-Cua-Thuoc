using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Globalization;
using Microsoft.Extensions.Configuration;
using Pharmacy.Application;

namespace Pharmacy.Infrastructure;

public sealed class ConsultationService(IConfiguration configuration) : IConsultationService
{
    private static readonly HttpClient HttpClient = new();

    public async Task<MedicineConsultationResponse> SearchMedicineAsync(MedicineConsultationRequest request, CancellationToken cancellationToken)
    {
        var medicineName = request.MedicineName.Trim();
        if (string.IsNullOrWhiteSpace(medicineName))
        {
            throw new InvalidOperationException("Vui lòng nhập tên thuốc cần tư vấn.");
        }

        var apiKey = configuration["Tavily:ApiKey"];
        var endpoint = configuration["Tavily:Endpoint"] ?? "https://api.tavily.com/search";
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("Chưa cấu hình dịch vụ tư vấn thuốc.");
        }

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, endpoint);
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        var searchKeyword = RemoveVietnameseDiacritics(medicineName);
        var body = JsonSerializer.Serialize(new
        {
            query = $"site:nhathuoclongchau.com.vn/thuoc \"{searchKeyword}\"",
            search_depth = "basic",
            max_results = 1,
            include_answer = false,
            include_raw_content = true
        });
        httpRequest.Content = new StringContent(body, Encoding.UTF8, "application/json");

        using var response = await HttpClient.SendAsync(httpRequest, cancellationToken);
        var content = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            var detail = TryReadErrorMessage(content);
            if (!string.IsNullOrWhiteSpace(detail))
            {
                Console.WriteLine($"Medicine consultation search failed ({(int)response.StatusCode}): {detail}");
            }

            throw new InvalidOperationException($"Không lấy được thông tin tư vấn thuốc. Mã lỗi: {(int)response.StatusCode}.");
        }

        using var document = JsonDocument.Parse(content);
        var root = document.RootElement;
        var firstResult = root.TryGetProperty("results", out var results) && results.ValueKind == JsonValueKind.Array && results.GetArrayLength() > 0
            ? results[0]
            : default;

        var title = firstResult.ValueKind == JsonValueKind.Object ? GetString(firstResult, "title") : string.Empty;
        var url = firstResult.ValueKind == JsonValueKind.Object ? GetString(firstResult, "url") : string.Empty;
        var snippet = firstResult.ValueKind == JsonValueKind.Object ? GetString(firstResult, "content") : string.Empty;
        var rawContent = firstResult.ValueKind == JsonValueKind.Object ? GetString(firstResult, "raw_content") : string.Empty;
        if (!IsLongChauMedicineUrl(url))
        {
            throw new InvalidOperationException("Không tìm thấy thông tin phù hợp cho thuốc này.");
        }

        var summary = BuildMedicineSummary(medicineName, title, rawContent, snippet);

        if (string.IsNullOrWhiteSpace(summary) && string.IsNullOrWhiteSpace(snippet))
        {
            throw new InvalidOperationException("Không tìm thấy thông tin phù hợp cho thuốc này.");
        }

        return new MedicineConsultationResponse(
            medicineName,
            summary.Trim(),
            string.IsNullOrWhiteSpace(title) ? "Nhà thuốc Long Châu" : title.Trim(),
            url.Trim(),
            snippet.Trim());
    }

    private static string GetString(JsonElement element, string propertyName)
    {
        return element.TryGetProperty(propertyName, out var property) && property.ValueKind == JsonValueKind.String
            ? property.GetString() ?? string.Empty
            : string.Empty;
    }

    private static string TryReadErrorMessage(string content)
    {
        try
        {
            using var document = JsonDocument.Parse(content);
            var root = document.RootElement;
            foreach (var propertyName in new[] { "detail", "message", "error" })
            {
                var message = GetString(root, propertyName);
                if (!string.IsNullOrWhiteSpace(message))
                {
                    return message;
                }
            }

            return string.Empty;
        }
        catch (JsonException)
        {
            return string.Empty;
        }
    }

    private static bool IsLongChauMedicineUrl(string url)
    {
        return Uri.TryCreate(url, UriKind.Absolute, out var uri)
            && uri.Host.Contains("nhathuoclongchau.com.vn", StringComparison.OrdinalIgnoreCase)
            && uri.AbsolutePath.StartsWith("/thuoc", StringComparison.OrdinalIgnoreCase);
    }

    private static string BuildMedicineSummary(string medicineName, string title, string rawContent, string snippet)
    {
        var source = NormalizeContent(string.IsNullOrWhiteSpace(rawContent) ? snippet : rawContent);
        var productName = CleanLine(title);
        var description = FirstUsefulLine(source, medicineName);
        var use = SectionText(source, ["Công dụng", "Chỉ định"]);
        var dosage = SectionText(source, ["Cách dùng", "Liều dùng"]);
        var sideEffect = SectionText(source, ["Tác dụng phụ"]);
        var warning = SectionText(source, ["Lưu ý", "Thận trọng khi sử dụng", "Chống chỉ định"]);

        var lines = new List<string>
        {
            $"Thông tin thuốc: {medicineName}"
        };
        if (!string.IsNullOrWhiteSpace(productName))
        {
            lines.Add($"Tên trên trang thuốc: {productName}");
        }
        if (!string.IsNullOrWhiteSpace(description))
        {
            lines.Add($"Thông tin chính: {description}");
        }
        if (!string.IsNullOrWhiteSpace(use))
        {
            lines.Add($"Công dụng/Chỉ định: {use}");
        }
        if (!string.IsNullOrWhiteSpace(dosage))
        {
            lines.Add($"Cách dùng/Liều dùng: {dosage}");
        }
        if (!string.IsNullOrWhiteSpace(sideEffect))
        {
            lines.Add($"Tác dụng phụ: {sideEffect}");
        }
        if (!string.IsNullOrWhiteSpace(warning))
        {
            lines.Add($"Lưu ý: {warning}");
        }

        lines.Add("Nội dung chỉ dùng để tham khảo, không thay thế tư vấn của bác sĩ hoặc dược sĩ.");
        return string.Join("\n\n", lines);
    }

    private static string NormalizeContent(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var lines = value
            .Replace("\r", "\n")
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(CleanLine)
            .Where(line => line.Length > 0
                && !line.StartsWith("!", StringComparison.Ordinal)
                && !line.StartsWith("http", StringComparison.OrdinalIgnoreCase)
                && !line.Contains("cdn.nhathuoclongchau", StringComparison.OrdinalIgnoreCase)
                && !line.Contains("TẢI ỨNG DỤNG", StringComparison.OrdinalIgnoreCase)
                && !line.Contains("HỖ TRỢ THANH TOÁN", StringComparison.OrdinalIgnoreCase)
                && !line.Contains("KẾT NỐI VỚI", StringComparison.OrdinalIgnoreCase)
                && !line.Contains("Đánh giá sản phẩm", StringComparison.OrdinalIgnoreCase)
                && !line.Contains("Hỏi đáp", StringComparison.OrdinalIgnoreCase)
                && !line.Contains("Tổng đài", StringComparison.OrdinalIgnoreCase))
            .Distinct()
            .ToList();
        return string.Join("\n", lines);
    }

    private static string CleanLine(string value)
    {
        return value
            .Replace("#", string.Empty)
            .Replace("*", string.Empty)
            .Replace("[", string.Empty)
            .Replace("]", string.Empty)
            .Trim();
    }

    private static string FirstUsefulLine(string source, string medicineName)
    {
        var keyword = RemoveVietnameseDiacritics(medicineName).ToLowerInvariant();
        return source
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(line => line.Length is > 80 and < 500)
            .FirstOrDefault(line => RemoveVietnameseDiacritics(line).ToLowerInvariant().Contains(keyword.Split(' ')[0])) ?? string.Empty;
    }

    private static string SectionText(string source, IReadOnlyList<string> headings)
    {
        var lines = source.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        for (var index = 0; index < lines.Length; index++)
        {
            if (!headings.Any(heading => lines[index].Contains(heading, StringComparison.OrdinalIgnoreCase)))
            {
                continue;
            }

            var content = lines
                .Skip(index + 1)
                .TakeWhile(line => !IsHeading(line))
                .Where(line => line.Length > 20)
                .Take(2);
            return LimitText(string.Join(" ", content), 420);
        }

        return string.Empty;
    }

    private static bool IsHeading(string line)
    {
        var headings = new[]
        {
            "Công dụng", "Cách dùng", "Tác dụng phụ", "Lưu ý", "Bảo quản", "Thành phần", "Chống chỉ định", "Dược lực học", "Câu hỏi thường gặp"
        };
        return line.Length < 80 && headings.Any(heading => line.Contains(heading, StringComparison.OrdinalIgnoreCase));
    }

    private static string LimitText(string value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value) || value.Length <= maxLength)
        {
            return value.Trim();
        }

        return value[..maxLength].TrimEnd() + "...";
    }

    private static string RemoveVietnameseDiacritics(string value)
    {
        var normalized = value.Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder(normalized.Length);
        foreach (var character in normalized)
        {
            var category = CharUnicodeInfo.GetUnicodeCategory(character);
            if (category != UnicodeCategory.NonSpacingMark)
            {
                builder.Append(character == 'đ' ? 'd' : character == 'Đ' ? 'D' : character);
            }
        }

        return builder.ToString().Normalize(NormalizationForm.FormC);
    }
}
