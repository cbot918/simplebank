postgres:
	docker run --name postgres12 -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:12-alpine

createdb:
	docker exec -it postgres12 createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres12 dropdb simple_bank

migrateup:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose up

migratedown:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose down

rec-sqlcc:
	docker run --rm -v "%cd%:/src" -w /src kjconroy/sqlc generate

sqlc:
	sqlc generate

mockgen:
	mockgen -destination db/mock/store.go github.com/nodev918/simplebank/db/sqlc Store

test:
	go test -v -cover ./...

server:
	go run main.go

.PHONEY: postgres createdb dropdb migrate test sqlc server mockgen

