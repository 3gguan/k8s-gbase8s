package service

import (
	"gbase8s-server/entity"
	"gbase8s-server/utils"
	"github.com/gin-gonic/gin"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
)

var mu sync.Mutex

func GetTape(context *gin.Context) {
	mu.Lock()
	defer mu.Unlock()
	fileName := filepath.Join(entity.TAPE_PATH, entity.TAPE_NAME)
	_ = os.Remove(fileName)
	err := exec.Command("bash", "-c", "ontape -s -L 0 -t STDIO >"+fileName).Run()
	if err != nil {
		context.JSON(http.StatusNotFound, entity.Response{
			Code:    entity.RESP_FAILED,
			Message: err.Error(),
		})
		utils.Log.Errorf("ontape failed, err: %s", err.Error())
		return
	}

	context.Header("Content-Type", "application/octet-stream")
	context.Header("Content-Disposition", "attachment;filename="+entity.TAPE_NAME)
	context.Header("Content-Transfer-Encoding", "binary")
	context.File(fileName)
	return
}
