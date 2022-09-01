package router

import (
	"gbase8s-server/service"
	"github.com/gin-gonic/gin"
)

func Init(g *gin.Engine) {
	api := g.Group("/api")
	api.GET("/gettape", service.GetTape)
	api.GET("/connect", service.Connect)
	api.GET("/getstatus", service.GetStatus)
	api.POST("/exec", service.Exec)
}
