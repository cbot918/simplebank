package main

import (
	"database/sql"
	"log"

	_ "github.com/lib/pq"
	"github.com/nodev918/simplebank/api"
	db "github.com/nodev918/simplebank/db/sqlc"
	"github.com/nodev918/simplebank/util"
)

func main() {
	config, err := util.LoadConfig(".")
	if err != nil {
		log.Fatal("cannot load config: ", err)
	}

	conn, err := sql.Open(config.DBDriver, config.DBSource)
	if err != nil {
		log.Fatal("connect connect to db:", err)
	}

	store := db.NewStore(conn)
	server := api.NewServer(store)

	err = server.Start(config.ServerAddress)
	if err != nil {
		log.Fatal("can't start server")
	}
}
