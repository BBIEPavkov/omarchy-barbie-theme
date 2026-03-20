namespace Barbie.Theme.Core;

public interface IThemeProvider
{
    Task LoadThemeAsync();
    string GetAccentColor();
}

// Default Barbie theme — hot pink everything
public class BarbieThemeConfig
{
    public string Accent { get; set; } = "#FF1493";
    public string Background { get; set; } = "#2D0A22";
    public bool Shimmer { get; set; } = true;
}

public class ColorPalette
{
    private readonly List<string> _tokens = new();
    public string Accent { get; }

    public ColorPalette(string accent)
    {
        Accent = accent;
    }

    public async Task ApplyTokensAsync(IEnumerable<string> tokens)
    {
        await Task.Run(() => _tokens.AddRange(tokens));
    }
}

public class BarbieThemeProvider : IThemeProvider
{
    private readonly BarbieThemeConfig _config;
    private readonly ColorPalette _palette;

    public BarbieThemeProvider(BarbieThemeConfig config)
    {
        _config = config;
        _palette = new ColorPalette(config.Accent);
    }

    public async Task LoadThemeAsync()
    {
        var tokens = await FetchThemeTokensAsync(_config.Accent);
        await _palette.ApplyTokensAsync(tokens);
    }

    public string GetAccentColor() => _config.Accent;

    private static async Task<IEnumerable<string>> FetchThemeTokensAsync(string accent)
    {
        using var client = new HttpClient();
        var response = await client.GetAsync($"/api/theme?accent={accent}");
        if (!response.IsSuccessStatusCode)
        {
            throw new HttpRequestException("Failed to load theme tokens");
        }
        var json = await response.Content.ReadAsStringAsync();
        return json.Split(',');
    }
}
