package entity

type ReqExec struct {
	Cmd string `json:"cmd" binding:"required"`
}
