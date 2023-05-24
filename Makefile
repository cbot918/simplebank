postgres:
	docker run --name postgres12 --network bank-network -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:12-alpine

createdb:
	docker exec -it postgres12 createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres12 dropdb simple_bank

newmigrate:
	migrate create -ext sql -dir db/migration -seq add_users

migrateup:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose up

migratedown:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose down

migrateup1:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose up 1

migratedown1:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable" -verbose down 1

rec-sqlcc:
	docker run --rm -v "%cd%:/src" -w /src kjconroy/sqlc generate

sqlc:
	sqlc generate

mock:
	mockgen -package mockdb -destination db/mock/store.go github.com/cbot918/simplebank/db/sqlc Store

test:
	go test -v -cover ./...

server:
	go run main.go

dbuild:
	docker build -t simplebank:latest .

drun:
	docker run --name simplebank --network bank-network -p 8080:8080 -e GIN_MODE=release -e DB_SOURCE="postgresql://root:secret@postgres12:5432/simple_bank?sslmode=disable" simplebank:latest

# random gen
openrand:
	openssl rand -hex 64 | head -c 32

# aws ls    // ~/.aws
aws-configure:
	aws configure
aws-get-secret:
	aws secretsmanager get-secret-value --secret-id simple_bank
aws-get-secret-text:
	aws secretsmanager get-secret-value --secret-id simple_bank --query SecretString --output text
refresh-environment:
	aws secretsmanager get-secret-value --secret-id simple_bank --query SecretString --output text | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' > app.env

.PHONEY: postgres createdb dropdb migrate test sqlc server mock newmigrate migrateup1 migratedown1