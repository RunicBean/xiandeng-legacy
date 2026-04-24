# local
migrate -source file://migrations -database "postgres://root:mysecretpassword@localhost:5432/yanban?sslmode=disable" up

# supabase test
migrate -source file://migrations -database "postgresql://postgres.pgqwbrpgagsrvtwyanzw:t6A11RkOryZdgJO0@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=disable" up

# production script
migrate -source file://migrations -database "postgres://migration:Tl5%40t92Wqfr37@pgm-uf64n4wc021w724cro.pg.rds.aliyuncs.com:5432/yanban?sslmode=disable" up