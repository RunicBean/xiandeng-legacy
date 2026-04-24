# Database change of Xiandeng
# 部署规则
分 develop branch 和 main branch，merge 到 develop branch 就会自动部署到测试环境，merge 到 main branch 就会自动部署到正式环境。

监测迁移文件格式：
- 文件开头为六位数字，代表迁移版本；
- 第一个下划线后到扩展名`.up.sql`前均为本次迁移备注；
- 以`.up.sql`结尾的文件才会被识别为迁移文件。
# 开发方式
- 在develop branch 开发，未完成之前不要添加`.up.sql`扩展名，添加扩展名就代表会被部署到测试环境。
- 数据库部署需先于服务部署。
- 任何`.up.sql`文件在上传到 repo 前，必须现在 localhost 环境执行通过，确认无误再上传。例如：
`migrate -source file://migrations -database "postgres://root:mysecretpassword@localhost:5432/yanban?sslmode=disable" up`