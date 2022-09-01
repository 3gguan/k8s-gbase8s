package service

import (
	"gbase8s-server/entity"
	"github.com/gin-gonic/gin"
	"net/http"
)

func Connect(context *gin.Context) {
	context.JSON(http.StatusOK, entity.Response{
		Code:    entity.RESP_SUCCESS,
		Message: "connect success",
	})
}
