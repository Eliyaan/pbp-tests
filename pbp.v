import sync.stdatomic as atom
import datatypes as dt

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

struct FanOut[T] {
mut:
	fan_out []&AtomicQueue[T]
}

fn (mut f FanOut[T]) push(val T) {
	for mut o in f.fan_out {
		o.push(val)
	}
}

interface Part {
mut:
	ready &atom.AtomicVal[bool]
	run()
}
