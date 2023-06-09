DB_URL=postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable

postgres:
	docker run --name postgres12 --network bank-network -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:12-alpine

createdb:
	docker exec -it postgres12 createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres12 dropdb simple_bank

newmigrate:
	migrate create -ext sql -dir db/migration -seq $(name)

migrateup:
	migrate -path db/migration -database "$(DB_URL)" -verbose up

migratedown:
	migrate -path db/migration -database "$(DB_URL)" -verbose down

migrateup1:
	migrate -path db/migration -database "$(DB_URL)" -verbose up 1

migratedown1:
	migrate -path db/migration -database "$(DB_URL)" -verbose down 1

rec-sqlcc:
	docker run --rm -v "%cd%:/src" -w /src kjconroy/sqlc generate

sqlc:
	sqlc generate

mock:
	mockgen -package mockdb -destination db/mock/store.go github.com/cbot918/simplebank/db/sqlc Store
	mockgen -package mockwk -destination worker/mock/distributor.go github.com/cbot918/simplebank/worker TaskDistributor

test:
	go test -v -cover -short ./...
# go test -v -cover -short $$(go list ./... | grep -v /private/)


server:
	go run main.go

# docker

dbuild:
	docker build -t simplebank:latest .

drun:
	docker run --name simplebank --network bank-network -p 8080:8080 -e GIN_MODE=release -e DB_SOURCE="postgresql://root:secret@postgres12:5432/simple_bank?sslmode=disable" simplebank:latest

dcup:
	docker-compose up --build --force-recreate

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

erc-password:
	aws ecr get-login-password
ecr-login:
	aws ecr get-login-password | docker login --username AWS --password-stdin 301621304382.dkr.ecr.us-east-2.amazonaws.com



# aws-eks
kube-update-config:
	aws eks update-kubeconfig --name simple-bank --region us-east-2
kube-use-config:
	kubectl use-context arn:aws:eks:us-east-2:301621304382:cluster/simple-bank
kube-get-info:
	kubectl cluster-info


# dbdocs dbml
dbdocs-install:
	npm i -g dbdocs
dbdocs-login:
	dbdocs login
dbdocs-build: #key script
	dbdocs build doc/db.dbml
dbdocs-set-password:
	dbdocs password --set 12345 --project BankingService
dbml-install:
	npm i -g @dbml/cli
### dbml2sql << binary_name
db_schema: #key script
	dbml2sql --postgres -o doc/schema.sql doc/db.dbml


# protoc
protoc-install:
# install protoc
	curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v3.15.8/protoc-3.15.8-linux-x86_64.zip
	unzip protoc-3.15.8-linux-x86_64.zip -d $HOME/.local
	export PATH="$PATH:$HOME/.local/bin"
	sudo cp -rf ~/.local/include/google ~/.local/bin
# install protoc-gen-go and protoc-gen-go-grpc
	go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2
	protoc --version
	protoc-gen-go --version
	protoc-gen-go-grpc --version
	export PATH="$PATH:$(go env GOPATH)/bin"

proto:
	rm -f pb/*.go
	rm -f doc/swagger/*.swagger.json
	protoc \
	--proto_path=proto --go_out=pb --go_opt=paths=source_relative \
	--go-grpc_out=pb --go-grpc_opt=paths=source_relative \
	--grpc-gateway_out=pb --grpc-gateway_opt=paths=source_relative \
	--openapiv2_out=doc/swagger --openapiv2_opt=allow_merge=true,merge_file_name=simple_bank \
	proto/*.proto
	statik -src=./doc/swagger -dest=./doc

# evans
evans-install:
	go install github.com/ktr0731/evans@latest

evans:
	evans --host localhost --port 9090 -r repl

# gRPC gateway : gg
gg-install:
	mkdir -p proto/google/api
	curl -o proto/google/api/annotations.proto -OL https://raw.githubusercontent.com/googleapis/googleapis/master/google/api/annotations.proto 
	curl -o proto/google/api/field_behavior.proto -OL https://raw.githubusercontent.com/googleapis/googleapis/master/google/api/field_behavior.proto 
	curl -o proto/google/api/http.proto -OL https://raw.githubusercontent.com/googleapis/googleapis/master/google/api/http.proto
	curl -o proto/google/api/httpbody.proto -OL https://raw.githubusercontent.com/googleapis/googleapis/master/google/api/httpbody.proto 

# redis
redis:
	docker run --name redis -p 6379:6379 -d redis:7-alpine
redis-ping:
	docker exec -it redis redis-cli ping

.PHONY: postgres createdb dropdb migrate test sqlc server mock newmigrate migrateup1 migratedown1 proto gg-install redis