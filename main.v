import sync.stdatomic as atom
import runtime
import datatypes as dt	

// TODO: represent links with an input queue and an array of outputs queues to enable fan out

fn main() {
	// datastructures
	mut input_1 := AtomicQueue[bool]{}
	mut input_2 := AtomicQueue[bool]{}
	mut threes := AtomicQueue[int]{}
	mut fives := AtomicQueue[int]{}
	mut add_results := AtomicQueue[int]{}
	mut parts := []Part{}
	parts << Out3{in: &input_1, out: &threes}
	parts << Out5{in: &input_2, out: &fives}
	parts << Add{a_in: &threes, b_in: &fives, out: &add_results}
	parts << PrintInt{in: &add_results}
	
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
	f fn (mut _in AtomicQueue[bool], mut _out AtomicQueue[int]) = out3
mut: 
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	in &AtomicQueue[bool]
	out &AtomicQueue[int]
}

fn (mut o Out3) run() {
	o.f(mut o.in, mut o.out)
}

fn out3(mut _in AtomicQueue[bool], mut _out AtomicQueue[int]) {
	do_output := _in.pop() or { return }
	if do_output {
		_out.push(3)
	}
}

struct Out5 {
	f fn (mut _in AtomicQueue[bool], mut _out AtomicQueue[int]) = out5
mut: 
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	in &AtomicQueue[bool]
	out &AtomicQueue[int]
}

fn (mut o Out5) run() {
	o.f(mut o.in, mut o.out)
}

fn out5(mut _in AtomicQueue[bool], mut _out AtomicQueue[int]) {
	do_output := _in.pop() or { return }
	if do_output {
		_out.push(5)
	}
}

struct Add {
	f fn (mut a_in AtomicQueue[int], mut b_in AtomicQueue[int], mut _out AtomicQueue[int]) = add
mut: 
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	a_in &AtomicQueue[int]
	b_in &AtomicQueue[int]
	out &AtomicQueue[int]
}

fn (mut a Add) run() {
	a.f(mut a.a_in, mut a.b_in, mut a.out)
}

fn add(mut a_in AtomicQueue[int], mut b_in AtomicQueue[int], mut _out AtomicQueue[int]) {
	if !a_in.is_empty() && !b_in.is_empty() {
		a := a_in.pop() or { return }
		b := b_in.pop() or { panic('b was empty so the a value is lost') }
		_out.push(a + b)
	}
}

struct PrintInt {
	f fn (mut _in AtomicQueue[int]) = print_int
mut: 
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	in &AtomicQueue[int]
}

fn (mut a PrintInt) run() {
	a.f(mut a.in)
}

fn print_int(mut _in AtomicQueue[int]) {
	println(_in.pop() or { return })
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
