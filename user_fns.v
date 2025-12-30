fn out3(do_output bool) ?int {
	if do_output {
		return 3
	}
	return none
}

fn out5(do_output bool) ?int {
	if do_output {
		return 5
	}
	return none
}

fn add(a int, b int) int {
	return a + b
}

fn print_int(a int) {
	println(a)
}
