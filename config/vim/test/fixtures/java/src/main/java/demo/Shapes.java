package demo;

import java.util.function.Supplier;

public class Shapes {
    private final int size;

    public Shapes(int size) {
        this.size = size;
    }

    /**
     * The area.
     */
    public int area() {
        return size * size;
    }

    public Supplier<Integer> lazyArea() {
        return () -> {
            return area();
        };
    }

    static class Inner {
        void hello() {
            System.out.println("hello");
        }

        interface Visitor {
            void visit(Shapes s);
        }
    }

    public static void main(String[] args) {
        Shapes shapes = new Shapes(2);
        System.out.println(shapes.area());
    }
}
