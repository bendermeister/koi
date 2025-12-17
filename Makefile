help:
	# test, test all repos
	# backend, run the backend server
	# frontend, run the frontend server

test:
	cd backend && gleam test
	cd frontend && gleam test
	cd middle && gleam test

backend:
	cd backend && gleam run

frontend:
	cd frontend && gleam run -m lustre/dev start

.PHONY: help test backend frontend
