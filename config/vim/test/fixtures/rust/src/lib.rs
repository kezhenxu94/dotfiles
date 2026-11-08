pub struct Point {
    pub x: i32,
}

impl Point {
    pub fn new(x: i32) -> Self {
        Point { x }
    }

    pub fn get(&self) -> i32 {
        let s: i32 = "x";
        self.x + s
    }
}

pub fn add(a: i32,b: i32) -> i32 { a+b }
