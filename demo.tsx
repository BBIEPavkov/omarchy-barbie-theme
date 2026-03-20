interface BarbieThemeConfig {
  accent: string;
  background: string;
  shimmer: boolean;
}

interface ThemeTokens {
  primary: string;
  secondary: string;
}

// Default Barbie theme — hot pink everything
const defaultConfig: BarbieThemeConfig = {
  accent: "#FF1493",
  background: "#2D0A22",
  shimmer: true,
};

class ColorPalette {
  private readonly tokens: string[] = [];

  constructor(public accent: string) {}

  public async applyTokens(tokens: ThemeTokens): Promise<void> {
    this.tokens.push(tokens.primary, tokens.secondary);
  }
}

class BarbieThemeProvider {
  private readonly config: BarbieThemeConfig;
  private palette: ColorPalette;

  constructor(config: BarbieThemeConfig = defaultConfig) {
    this.config = config;
    this.palette = new ColorPalette(config.accent);
  }

  public async loadTheme(): Promise<void> {
    const tokens = await fetchThemeTokens(this.config.accent);
    await this.palette.applyTokens(tokens);
  }

  public getAccentColor(): string {
    return this.config.accent;
  }
}

async function fetchThemeTokens(accent: string): Promise<ThemeTokens> {
  const response = await fetch(`/api/theme?accent=${accent}`);
  if (!response.ok) {
    throw new Error("Failed to load theme tokens");
  }
  return await response.json();
}

const provider = new BarbieThemeProvider(defaultConfig);
provider.loadTheme();
