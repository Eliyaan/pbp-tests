import pbp
import sync.stdatomic as atom
import runtime

// TODO: autogenerate this file

fn main() {
	// datastructures
	mut input_1 := pbp.AtomicQueue[bool]{}
	mut input_2 := pbp.AtomicQueue[bool]{}
	mut threes := pbp.AtomicQueue[int]{}
	mut fives := pbp.AtomicQueue[int]{}
	mut add_results := pbp.AtomicQueue[int]{}
	mut parts := []pbp.Part{}
	parts << Out3{
		a_in:  &input_1
		b_out: pbp.FanOut[int]{[&threes]}
	}
	parts << Out5{
		a_in:  &input_2
		b_out: pbp.FanOut[int]{[&fives]}
	}
	parts << Add{
		a_in:  &threes
		b_in:  &fives
		c_out: pbp.FanOut[int]{[&add_results]}
	}
	parts << PrintInt{
		a_in: &add_results
	}

	// value init
	input_1.push(false)
	input_1.push(true)
	input_2.push(true)

	// run
	mut ths := []thread{}
	for _ in 0 .. runtime.nr_cpus() {
		ths << spawn pbp.part_runner(mut parts)
	}
	ths.wait()
}

struct Out3 {
	f fn (do_output bool) int = out3
mut:
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	a_in  &pbp.AtomicQueue[bool]
	b_out pbp.FanOut[int]
}

fn (mut o Out3) run() {
	a_in := o.a_in.pop() or { return }
	b_out := o.f(a_in)
	o.b_out.push(b_out)
}

struct Out5 {
	f fn (do_output bool) int = out5
mut:
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	a_in  &pbp.AtomicQueue[bool]
	b_out pbp.FanOut[int]
}

fn (mut o Out5) run() {
	a_in := o.a_in.pop() or { return }
	b_out := o.f(a_in)
	o.b_out.push(b_out)
}

struct Add {
	f fn (a int, b int) int = add
mut:
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	a_in  &pbp.AtomicQueue[int]
	b_in  &pbp.AtomicQueue[int]
	c_out pbp.FanOut[int]
}

fn (mut a Add) run() {
	if !a.a_in.is_empty() && !a.b_in.is_empty() {
		a_in := a.a_in.pop() or { return }
		b_in := a.b_in.pop() or { panic('b was empty so the a value is lost') }
		c_out := a.f(a_in, b_in)
		a.c_out.push(c_out)
	}
}

struct PrintInt {
	f fn (a int) = print_int
mut:
	ready &atom.AtomicVal[bool] = atom.new_atomic(true)
	a_in  &pbp.AtomicQueue[int]
}

fn (mut a PrintInt) run() {
	a_in := a.a_in.pop() or { return }
	a.f(a_in)
}
