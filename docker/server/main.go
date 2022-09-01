package main

import (
	"flag"
	"gbase8s-server/router"
	"gbase8s-server/utils"
	"github.com/gin-gonic/gin"
)

func main() {
	var logLevel uint
	var logPath string
	flag.UintVar(&logLevel, "l", 5, "log level, 0 panic, 1 fatal, 2 error, 3 warn, 4 info, 5 debug, 6 trace")
	flag.StringVar(&logPath, "p", "./logs", "log path")

	flag.Parse()
	utils.LogInit(logLevel, logPath)
	engine := gin.Default()
	engine.Use(utils.LogToFile())
	router.Init(engine)

	engine.Run(":8080")
}
