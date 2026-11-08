import { Point } from './point';

export class Shape {
  origin: Point = { x: 0, y: 0 };

  area(): number {
    return 0;
  }

  move(dx: number): void {
    this.origin.x += dx;
  }
}

const shape = new Shape();
export const label: string = shape.area();
