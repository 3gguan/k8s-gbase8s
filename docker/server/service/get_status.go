package service

import (
	"gbase8s-server/entity"
	"gbase8s-server/utils"
	"github.com/gin-gonic/gin"
	"net/http"
	"os/exec"
)

func GetStatus(context *gin.Context) {
	out, err := exec.Command("bash", "-c", "onstat -g rss verbose").CombinedOutput()
	if err != nil {
		context.JSON(http.StatusOK, entity.Response{
			Code:    entity.RESP_FAILED,
			Message: err.Error(),
		})
		utils.Log.Errorf("onstat failed, err: %s", err.Error())
		return
	}

	context.JSON(http.StatusOK, entity.Response{
		Code:    entity.RESP_SUCCESS,
		Message: "get oninit status success",
		Data:    string(out),
	})
	return
}
