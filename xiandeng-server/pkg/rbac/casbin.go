package rbac

import (
	pgxadapter "github.com/pckhoi/casbin-pgx-adapter/v3"
	"xiandeng.net.cn/server/pkg/config"

	"github.com/casbin/casbin/v2"
)

func PgxAdapter(connString string, database string) (*pgxadapter.Adapter, error) {
	return pgxadapter.NewAdapter(
		connString,
		pgxadapter.WithTableName("casbinrule"),
		pgxadapter.WithDatabase(database),
	)
}

func NewEnforcer(conf *config.Config) *casbin.Enforcer {
	a, err := PgxAdapter(conf.Database.CredInfo, conf.Database.DbName)
	if err != nil {
		panic(err)
	}

	// a, err := sqladapter.NewAdapter(db, "mysql", "CasbinRule")
	// if err != nil {
	// 	panic(err)
	// }

	e, err := casbin.NewEnforcer("pkg/rbac/rbac_model.conf", a)
	if err != nil {
		panic(err)
	}
	return e
}

// 检查用户是否有权限
func CheckPermission(e *casbin.Enforcer, sub, obj, act string) bool {
	ok, _ := e.Enforce(sub, obj, act)
	return ok
}

// 为用户添加角色
func AddRoleForUser(e *casbin.Enforcer, user, role string) bool {
	ok, _ := e.AddRoleForUser(user, role)
	return ok
}

// 为用户删除角色
func DeleteRoleForUser(e *casbin.Enforcer, user, role string) bool {
	ok, _ := e.DeleteRoleForUser(user, role)
	return ok
}

// 获取用户的所有角色
func GetRolesForUser(e *casbin.Enforcer, user string) []string {
	roles, _ := e.GetRolesForUser(user)
	return roles
}

// 获取具有特定角色的所有用户
func GetUsersForRole(e *casbin.Enforcer, role string) []string {
	users, _ := e.GetUsersForRole(role)
	return users
}

// 添加权限规则
func AddPolicy(e *casbin.Enforcer, sub, obj, act string) bool {
	ok, _ := e.AddPolicy(sub, obj, act)
	return ok
}

// 删除权限规则
func RemovePolicy(e *casbin.Enforcer, sub, obj, act string) bool {
	ok, _ := e.RemovePolicy(sub, obj, act)
	return ok
}

// 获取所有权限规则
func GetAllPolicies(e *casbin.Enforcer) [][]string {
	return e.GetPolicy()
}

// 保存所有规则到存储
func SavePolicy(e *casbin.Enforcer) error {
	return e.SavePolicy()
}

// 重新加载规则
func ReloadPolicy(e *casbin.Enforcer) error {
	return e.LoadPolicy()
}
