declare class ColorScheme {
  constructor();
  from_hue(n: number): ColorScheme;
  scheme(s: string): ColorScheme;
  variation(v: string): ColorScheme;
  colors(): string[];
}
declare const colorSchemeClass = ColorScheme;

declare module "color-scheme" {
  export = colorSchemeClass;
}
