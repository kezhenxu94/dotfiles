package main

import "fmt"

type Server struct {
	Name    string
	Address string
}

func (s *Server) Start() {}

func main() {
	srv := &Server{}
	fmt.Println(srv)
}
