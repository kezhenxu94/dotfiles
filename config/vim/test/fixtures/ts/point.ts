export interface Point {
  x: number;
  y: number;
}

export function makePoint(x: number, y: number): Point {
  return { x, y };
}
