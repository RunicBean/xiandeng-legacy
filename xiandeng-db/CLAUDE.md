# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a PostgreSQL database migrations repository for the Xienged application. It uses [golang-migrate](https://github.com/golang-migrate/migrate) for migration management.

## Common Commands

### Run Migrations
```bash
# Local development
migrate -source file://migrations -database "postgres://root:mysecretpassword@localhost:5432/yanban?sslmode=disable" up

# Supabase test environment
migrate -source file://migrations -database "postgresql://postgres.pgqwbrpgagsrvtwyanzw:t6A11RkOryZdgJO0@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=disable" up

# Production
migrate -source file://migrations -database "postgres://migration:Tl5%40t92Wqfr37@pgm-uf64n4wc021w724cro.pg.rds.aliyuncs.com:5432/yanban?sslmode=disable" up
```

### Rollback (down migration)
Replace `up` with `down` in the above commands.

## Migration File Format

- Files named `XXXXXXXX_description.up.sql` are forward migrations
- Files named `XXXXXXXX_description.down.sql` are rollback migrations
- The 6-digit prefix is the version number
- Only `.up.sql` files are recognized as valid migrations
- Example: `000109_DLYB_282.up.sql` and `000109_DLYB_282.down.sql`

## Development Workflow

1. Create migration files with `.up.sql` and `.down.sql` extensions
2. **Test migrations locally first** before committing
3. When working on `develop` branch: migrations auto-deploy to test environment on merge
4. When working on `main` branch: migrations auto-deploy to production on merge
5. **Database deployment must precede service deployment**

## Key Tables

The initial schema (`000000_init_tables.up.sql`) includes:
- `Users` - User accounts
- `Account` - Financial accounts with balance tracking
- `Guardian` - Parent/guardian relationships
- `AgentAttribute` - Agent (reseller) properties
- `StudentAttribute` - Student properties including MBTI
- `Major` - University major information
- `GovEnterprise` / `MajorEnterprise` - Enterprise data
- `AccountUserTaskData` - Task tracking

## Branch Strategy

- `develop` branch → test environment (auto-deploy)
- `main` branch → production environment (auto-deploy)
