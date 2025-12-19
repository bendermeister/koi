help:
	# test...........run all tests
	# check..........check every project
	# build..........build all projects
	# run............run the backend and the frontend server
	# run-backend....run the backend server
	# run-frontend...run the frontend dev server


test:
	cd ./backend/ && gleam test
	cd ./middle/ && gleam test
	cd ./frontend/ && gleam test

check:
	cd ./backend/ && gleam check
	cd ./middle/ && gleam check
	cd ./frontend/ && gleam check

build:
	# not implemented

run: 
	cd ./backend/ && gleam run &
	cd .frontend && gleam run -m lustre/dev start &

run-backend:
	cd ./backend/ && gleam run

run-frontend:
	cd .frontend && gleam run -m lustre/dev start


.PHONY: test check build run run-backend run-frontend
