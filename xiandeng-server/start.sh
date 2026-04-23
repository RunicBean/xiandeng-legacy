docker stop xiandeng-server && docker rm xiandeng-server
docker run \
--name xiandeng-server \
--network yanban \
-v /www/wwwroot/yanban/conf:/app/conf -d \
-p 8080:8080 \
registry-vpc.cn-shanghai.aliyuncs.com/dorian-acr/xiandeng-server