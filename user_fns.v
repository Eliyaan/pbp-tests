// need to mark the function that can be used as blocks as public to be picked up by `v doc .`

pub fn out3(do_output bool) ?int {
	if do_output {
		return 3
	}
	return none
}

pub fn out5(do_output bool) ?int {
	if do_output {
		return 5
	}
	return none
}

pub fn add(a int, b int) int {
	return a + b
}

pub fn print_int(a int) {
	println(a)
}
