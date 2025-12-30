import sync.stdatomic as atom
import runtime
import datatypes as dt	

fn main() {
	// datastructures
	mut input_1 := AtomicQueue[bool]{}
	mut input_2 := AtomicQueue[bool]{}
	mut threes := AtomicQueue[int]{}
	mut fives := AtomicQueue[int]{}
	mut add_results := AtomicQueue[int]{}
	mut parts := []Part{}
	parts << Out3{a_in: &input_1, b_out: FanOut[int]{[&threes]}}
	parts << Out5{a_in: &input_2, b_out: FanOut[int]{[&fives]}}
	parts << Add{a_in: &threes, b_in: &fives, c_out: FanOut[int]{[&add_results]}}
	parts << PrintInt{a_in: &add_results}
	
	// value init
	//input_1.push(false)
	input_1.push(true)
	input_2.push(true)

	// run
	mut ths := []thread{}
	for _ in 0 .. runtime.nr_cpus() {
		ths << spawn part_runner(mut parts)
	}
	ths.wait()
}

struct FanOut[T] {
mut:
	fan_out []&AtomicQueue[T]
}

fn (mut f FanOut[T]) push(val T) {
	for mut o in f.fan_out {
		o.push(val)
	}
}

fn part_runner(mut parts []Part) {
	for {
		for mut p in parts {
			if !p.ready.compare_and_swap(true, false) {
				continue
			}
			p.run()
			p.ready.store(true)
		}
	}
}

interface Part {
mut:
	ready &atom.AtomicVal[bool]
	run()
}

struct Out3 {
	f fn (do_output bool) ?int = out3
mut: 
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	a_in &AtomicQueue[bool]
	b_out FanOut[int]
}

fn (mut o Out3) run() {
	a_in := o.a_in.pop() or { return }
	b_out := o.f(a_in) or { return }
	o.b_out.push(b_out)
}

fn out3(do_output bool) ?int {
	if do_output {
		return 3
	}
	return none
}

struct Out5 {
	f fn (do_output bool) ?int = out5
mut: 
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	a_in &AtomicQueue[bool]
	b_out FanOut[int]
}

fn (mut o Out5) run() {
	a_in := o.a_in.pop() or { return }
	b_out := o.f(a_in) or { return }
	o.b_out.push(b_out)
}

fn out5(do_output bool) ?int {
	if do_output {
		return 5
	}
	return none
}

struct Add {
	f fn (a int, b int) int = add
mut: 
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	a_in &AtomicQueue[int]
	b_in &AtomicQueue[int]
	c_out FanOut[int]
}

fn (mut a Add) run() {
	if !a.a_in.is_empty() && !a.b_in.is_empty() {
		a_in := a.a_in.pop() or { return }
		b_in := a.b_in.pop() or { panic('b was empty so the a value is lost') }
		c_out := a.f(a_in, b_in)
		a.c_out.push(c_out)
	}
}

fn add(a int, b int) int {
	return a + b
}

struct PrintInt {
	f fn (a int) = print_int
mut: 
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	a_in &AtomicQueue[int]
}

fn (mut a PrintInt) run() {
	a_in := a.a_in.pop() or { return }
	a.f(a_in)
}

fn print_int(a int) {
	println(a)
}

struct AtomicQueue[T] {
mut:
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	queue dt.Queue[T]
}

fn (mut a AtomicQueue[T]) is_empty() bool {
	for !a.ready.compare_and_swap(true, false) {}
	empty := a.queue.is_empty()
	a.ready.store(true)
	return empty	
}

fn (mut a AtomicQueue[T]) pop() !T {
	for !a.ready.compare_and_swap(true, false) {}
	item := a.queue.pop()!
	a.ready.store(true)
	return item
}

fn (mut a AtomicQueue[T]) push(item T) {
	for !a.ready.compare_and_swap(true, false) {}
	a.queue.push(item)
	a.ready.store(true)
}
