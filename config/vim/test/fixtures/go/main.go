package main

import "fmt"

// Greeter greets people.
type Greeter interface {
	Greet(name string) string
}

type english struct {
	prefix string
}

func (e english) Greet(name string) string {
	return fmt.Sprintf("%s, %s", e.prefix, name)
}

func main() {
	var g Greeter = english{prefix: "Hello"}
	fmt.Println(g.Greet("world"))
}
