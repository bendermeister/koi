help:
	# test, test all repos

test:
	cd backend && gleam test
	cd frontend && gleam test
	cd middle && gleam test
