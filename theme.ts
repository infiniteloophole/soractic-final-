import { DefaultTheme } from '@react-navigation/native';

// Terminal-inspired brutalist theme system
export const terminalTheme = {
  colors: {
    // Core terminal colors
    terminal: {
      black: '#000000',
      white: '#FFFFFF',
      green: '#00FF00',
      amber: '#FFFF00',
      red: '#FF0000',
      gray: '#808080',
      darkGray: '#404040',
      brightGray: '#C0C0C0',
    },
    
    // Semantic color mapping
    background: '#000000',
    surface: '#000000',
    surfaceElevated: '#101010',
    
    text: {
      primary: '#FFFFFF',
      secondary: '#808080',
      accent: '#00FF00',
      warning: '#FFFF00',
      error: '#FF0000',
      prompt: '#00FF00',
    },
    
    border: {
      primary: '#FFFFFF',
      secondary: '#808080',
      accent: '#00FF00',
      error: '#FF0000',
    },
    
    button: {
      primary: {
        background: '#000000',
        border: '#FFFFFF',
        text: '#FFFFFF',
        hover: '#FFFFFF',
        hoverText: '#000000',
      },
      accent: {
        background: '#000000',
        border: '#00FF00',
        text: '#00FF00',
        hover: '#00FF00',
        hoverText: '#000000',
      },
      warning: {
        background: '#000000',
        border: '#FFFF00',
        text: '#FFFF00',
        hover: '#FFFF00',
        hoverText: '#000000',
      },
      danger: {
        background: '#000000',
        border: '#FF0000',
        text: '#FF0000',
        hover: '#FF0000',
        hoverText: '#000000',
      },
    },
    
    input: {
      background: '#000000',
      border: '#FFFFFF',
      text: '#FFFFFF',
      placeholder: '#808080',
      focus: '#00FF00',
    },
    
    chat: {
      ownMessage: '#00FF00',
      otherMessage: '#FFFFFF',
      systemMessage: '#FFFF00',
      errorMessage: '#FF0000',
    }
  },
  
  typography: {
    // Monospace font family stack
    fontFamily: {
      mono: 'JetBrains Mono, Fira Code, SF Mono, Monaco, Inconsolata, Roboto Mono, Courier New, monospace',
      display: 'JetBrains Mono, monospace',
    },
    
    fontSize: {
      xs: 10,
      sm: 12,
      base: 14,
      lg: 16,
      xl: 18,
      '2xl': 24,
      '3xl': 32,
    },
    
    lineHeight: {
      tight: 1.2,
      normal: 1.4,
      relaxed: 1.6,
    },
    
    fontWeight: {
      normal: '400',
      medium: '500',
      bold: '700',
    },
  },
  
  spacing: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    '2xl': 48,
  },
  
  borderWidth: {
    thin: 1,
    thick: 2,
    ultra: 3,
  },
  
  borderRadius: {
    none: 0, // Brutalist - no rounded corners
    sharp: 0,
  },
  
  effects: {
    cursor: {
      blinkDuration: 1000, // ms
    },
    typewriter: {
      speed: 50, // characters per second
    },
  },
  
  // ASCII art elements
  ascii: {
    prompt: '> ',
    loading: ['[    ]', '[=   ]', '[==  ]', '[=== ]', '[====]', '[ ===]', '[  ==]', '[   =]'],
    cursor: '█',
    borders: {
      horizontal: '─',
      vertical: '│',
      topLeft: '┌',
      topRight: '┐',
      bottomLeft: '└',
      bottomRight: '┘',
      cross: '┼',
    },
  },
};

// Navigation theme compatibility
export const navigationTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    primary: terminalTheme.colors.text.accent,
    background: terminalTheme.colors.background,
    card: terminalTheme.colors.surface,
    text: terminalTheme.colors.text.primary,
    border: terminalTheme.colors.border.secondary,
    notification: terminalTheme.colors.text.error,
  },
};

// Legacy theme for backward compatibility
export const theme = {
  ...terminalTheme,
};

export type TerminalTheme = typeof terminalTheme;
export type AppTheme = typeof theme;
