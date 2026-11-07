package bad

import "fmt"

func F(a int) {
	fmt.Printf("%d\n", "s")
	for i := 0; i < 3; i++ {
		_ = []int{1}[0:len([]int{1})]
	}
}
