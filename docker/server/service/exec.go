package service

import (
	"gbase8s-server/entity"
	"gbase8s-server/utils"
	"github.com/gin-gonic/gin"
	"net/http"
	"os/exec"
)

func Exec(context *gin.Context) {
	var req entity.ReqExec
	err := context.ShouldBindJSON(&req)
	if err != nil {
		context.JSON(http.StatusOK, entity.Response{
			Code:    entity.RESP_FAILED,
			Message: err.Error(),
		})
		utils.Log.Errorf("exec param error, %s", err.Error())
		return
	}

	if req.Cmd == "" {
		context.JSON(http.StatusOK, entity.Response{
			Code:    entity.RESP_FAILED,
			Message: err.Error(),
		})
		utils.Log.Errorf("exec cmd is null")
		return
	}

	out, err := exec.Command("bash", "-c", req.Cmd).CombinedOutput()
	if err != nil {
		context.JSON(http.StatusOK, entity.Response{
			Code:    entity.RESP_FAILED,
			Message: err.Error(),
		})
		utils.Log.Errorf("exec %s failed, err: %s", req.Cmd, err.Error())
		return
	}

	context.JSON(http.StatusOK, entity.Response{
		Code:    entity.RESP_SUCCESS,
		Message: "exec " + req.Cmd + " success",
		Data:    string(out),
	})

	return
}
