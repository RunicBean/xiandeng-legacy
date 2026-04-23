docker stop xiandeng-web && docker rm xiandeng-web
docker run \
--name xiandeng-web \
-v /www/wwwroot/yanban/gateway:/data/gateway \
--network yanban \
-p 443:443 -d \
registry-vpc.cn-shanghai.aliyuncs.com/dorian-acr/xiandeng-web:bf39309a2abb1dba65359ad2ed4906669684b677