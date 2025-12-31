// need to mark the function that can be used as blocks as public to be picked up by `v doc .`

pub fn out3() int {
	return 3
}

pub fn out5() int {
	return 5
}

pub fn add(a int, b int) int {
	return a + b
}

pub fn print_int(a int) {
	println(a)
}
