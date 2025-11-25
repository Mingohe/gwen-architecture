# Gwen Project - Makefile for common development tasks

# Auto-detect docker compose command (supports both 'docker compose' and 'docker-compose')
# Try 'docker compose' first (newer Docker versions), fallback to 'docker-compose' (older versions)
DOCKER_COMPOSE := $(shell docker compose version >/dev/null 2>&1 && echo 'docker compose' || (command -v docker-compose >/dev/null 2>&1 && echo docker-compose || echo 'docker compose'))

.PHONY: help start stop restart logs clean dev build test health env ports db-setup install-backend install-frontend run-backend run-frontend frontend-logs backend-logs dev-logs up down rebuild frontend-dev frontend-start frontend-stop frontend-restart frontend-logs-only backend-dev backend-start backend-stop backend-restart backend-logs-only pull

# Default target
help:
	@echo "Gwen Project Development Commands:"
	@echo ""
	@echo "🚀 Service Management:"
	@echo "  make pull      - Clone backend and frontend repositories"
	@echo "  make dev       - Start services in development mode (with hot reload & auto-rebuild)"
	@echo "  make stop      - Stop all services"
	@echo "  make restart   - Restart all services"
	@echo "  make logs      - View logs from all services"
	@echo "  make clean     - Clean up containers and volumes"
	@echo "  make build     - Rebuild all containers"
	@echo ""
	@echo "🔍 Monitoring & Testing:"
	@echo "  make health    - Check service health"
	@echo "  make test      - Run basic connectivity tests"
	@echo "  make ports     - Show service ports"
	@echo "  make env       - Show environment variables"
	@echo ""
	@echo "🛠️  Development Helpers:"
	@echo "  make install-backend - Install backend dependencies"
	@echo "  make install-frontend - Install frontend dependencies"
	@echo "  make run-backend     - Run backend in development mode"
	@echo "  make run-frontend   - Run frontend in development mode"
	@echo "  make db-setup       - Setup database (create, migrate, seed)"
	@echo ""
	@echo "🔧 Backend Only Commands:"
	@echo "  make backend-dev     - Start backend in development mode (Docker)"
	@echo "  make backend-start   - Start backend in production mode (Docker)"
	@echo "  make backend-stop    - Stop backend container"
	@echo "  make backend-restart - Restart backend container"
	@echo "  make backend-logs-only - View backend logs only"
	@echo ""
	@echo "🎨 Frontend Only Commands:"
	@echo "  make frontend-dev    - Start frontend in development mode (Docker)"
	@echo "  make frontend-start  - Start frontend in production mode (Docker)"
	@echo "  make frontend-stop   - Stop frontend container"
	@echo "  make frontend-restart - Restart frontend container"
	@echo "  make frontend-logs-only - View frontend logs only"
	@echo ""
	@echo "📊 Logs:"
	@echo "  make frontend-logs - View frontend logs"
	@echo "  make backend-logs  - View backend logs"
	@echo "  make dev-logs      - View all development logs"
	@echo ""

# Start all services (production mode)
start:
	@echo "🚀 Starting Gwen services in production mode..."
	$(DOCKER_COMPOSE) up -d
	@echo "✅ Services started!"
	@echo "🌐 Frontend: http://localhost:3201"
	@echo "🔧 Backend: http://localhost:3200"
	@echo "📝 Note: Production mode - no hot reload"

# Development mode with hot reload (fast start)
dev:
	@echo "🛠️  Starting Gwen in development mode..."
	@echo "📦 Installing dependencies if needed..."
	$(DOCKER_COMPOSE) up -d
	@echo "✅ Development environment ready!"
	@echo "🌐 Frontend: http://localhost:3201 (with hot reload)"
	@echo "🔧 Backend: http://localhost:3200 (with auto-reload)"
	@echo "🔄 Code changes will be automatically reloaded"

# Development mode with rebuild (when dependencies change)
dev-build:
	@echo "🛠️  Starting Gwen in development mode (with rebuild)..."
	@echo "📦 Installing dependencies if needed..."
	$(DOCKER_COMPOSE) up -d --build
	@echo "✅ Development environment ready!"
	@echo "🌐 Frontend: http://localhost:3201 (with hot reload)"
	@echo "🔧 Backend: http://localhost:3200 (with auto-reload)"
	@echo "🔄 Code changes will be automatically reloaded"

# Stop all services
stop:
	@echo "🛑 Stopping Gwen services..."
	$(DOCKER_COMPOSE) down
	@echo "✅ Services stopped!"

# Restart services
restart: stop start

# View logs
logs:
	@echo "📄 Viewing service logs (press Ctrl+C to exit)..."
	$(DOCKER_COMPOSE) logs -f

# Clean up
clean:
	@echo "🧹 Cleaning up containers and volumes..."
	$(DOCKER_COMPOSE) down -v --remove-orphans
	docker system prune -f
	@echo "✅ Cleanup completed!"

# Build containers
build:
	@echo "🔨 Building containers..."
	$(DOCKER_COMPOSE) build --no-cache
	@echo "✅ Build completed!"

# Health check
health:
	@echo "🏥 Checking service health..."
	@echo ""
	@echo "Frontend (Vue):"
	@curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:3201 || echo "  Status: Unavailable"
	@echo ""
	@echo "Backend (Rails):"
	@curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:3200 || echo "  Status: Unavailable"
	@echo ""

# Basic connectivity tests
test:
	@echo "🧪 Running basic connectivity tests..."
	@echo ""
	
	@echo "1. Testing Frontend (Vue)..."
	@if curl -s -f http://localhost:3201 > /dev/null; then \
		echo "  ✅ Frontend HTTP accessible"; \
	else \
		echo "  ❌ Frontend HTTP failed"; \
	fi
	
	@echo ""
	@echo "2. Testing Backend (Rails)..."
	@if curl -s -f http://localhost:3200 > /dev/null; then \
		echo "  ✅ Backend HTTP accessible"; \
	else \
		echo "  ❌ Backend HTTP failed"; \
	fi
	
	@echo ""
	@echo "Test completed!"

# Development helpers
install-backend:
	@echo "📦 Installing backend dependencies..."
	cd src/backend && bundle install
	@echo "✅ Backend dependencies installed!"

install-frontend:
	@echo "📦 Installing frontend dependencies..."
	cd src/frontend && npm install
	@echo "✅ Frontend dependencies installed!"

run-backend:
	@echo "🚀 Running backend in development mode..."
	cd src/backend && bundle exec rails server -p 3200

run-frontend:
	@echo "🚀 Running frontend in development mode..."
	cd src/frontend && npm run dev

# Backend only commands
backend-dev:
	@echo "🛠️  Starting Gwen backend in development mode..."
	@echo "📦 Building backend container if needed..."
	$(DOCKER_COMPOSE) up -d --build backend
	@echo "✅ Backend development environment ready!"
	@echo "🔧 Backend: http://localhost:3200 (with auto-reload)"
	@echo "🔄 Code changes will be automatically reloaded"

backend-start:
	@echo "🚀 Starting Gwen backend in production mode..."
	$(DOCKER_COMPOSE) up -d backend
	@echo "✅ Backend started!"
	@echo "🔧 Backend: http://localhost:3200"

backend-stop:
	@echo "🛑 Stopping Gwen backend..."
	$(DOCKER_COMPOSE) stop backend
	@echo "✅ Backend stopped!"

backend-restart: backend-stop backend-start

backend-logs-only:
	@echo "📄 Viewing backend logs (press Ctrl+C to exit)..."
	$(DOCKER_COMPOSE) logs -f backend

backend-logs-mariadb:
	@echo "📄 Viewing MariaDB logs..."
	$(DOCKER_COMPOSE) exec backend tail -f /var/log/supervisor/mariadb.out.log

backend-logs-redis:
	@echo "📄 Viewing Redis logs..."
	$(DOCKER_COMPOSE) exec backend tail -f /var/log/supervisor/redis.out.log

backend-logs-rails:
	@echo "📄 Viewing Rails logs..."
	$(DOCKER_COMPOSE) exec backend tail -f /var/log/supervisor/rails.out.log

backend-logs-sidekiq:
	@echo "📄 Viewing Sidekiq logs..."
	$(DOCKER_COMPOSE) exec backend tail -f /var/log/supervisor/sidekiq.out.log

backend-logs-all:
	@echo "📄 Viewing all backend service logs..."
	$(DOCKER_COMPOSE) exec backend tail -f /var/log/supervisor/*.out.log

# Frontend only commands
frontend-dev:
	@echo "🎨 Starting Gwen frontend in development mode..."
	@echo "📦 Building frontend container if needed..."
	$(DOCKER_COMPOSE) up -d --build frontend
	@echo "✅ Frontend development environment ready!"
	@echo "🌐 Frontend: http://localhost:3201 (with hot reload)"
	@echo "🔄 Code changes will be automatically reloaded"

frontend-start:
	@echo "🚀 Starting Gwen frontend in production mode..."
	$(DOCKER_COMPOSE) up -d frontend
	@echo "✅ Frontend started!"
	@echo "🌐 Frontend: http://localhost:3201"

frontend-stop:
	@echo "🛑 Stopping Gwen frontend..."
	$(DOCKER_COMPOSE) stop frontend
	@echo "✅ Frontend stopped!"

frontend-restart: frontend-stop frontend-start

frontend-logs-only:
	@echo "📄 Viewing frontend logs (press Ctrl+C to exit)..."
	$(DOCKER_COMPOSE) logs -f frontend

frontend-logs:
	$(DOCKER_COMPOSE) logs -f frontend

backend-logs:
	$(DOCKER_COMPOSE) logs -f backend

dev-logs:
	$(DOCKER_COMPOSE) logs -f

# Environment management
env:
	@echo "📋 Current environment variables:"
	@echo "  VITE_PORT: ${VITE_PORT:-3201}"
	@echo "  FRONTEND_PORT: ${FRONTEND_PORT:-3201}"
	@echo "  PORT: ${PORT:-3200}"
	@echo "  BACKEND_PORT: ${BACKEND_PORT:-3200}"

# Port configuration
ports:
	@echo "🔌 Service ports:"
	@echo "  Frontend: http://localhost:3201"
	@echo "  Backend (Rails): http://localhost:3200"
	@echo "  Sidekiq Web UI: http://localhost:3200/sidekiq (通过 Rails 路由访问)"
	@echo "  MariaDB: localhost:13306"
	@echo "  Redis: localhost:6380"

# Database setup
db-setup:
	@echo "🗄️  Setting up database..."
	$(DOCKER_COMPOSE) exec backend bundle exec rails db:create
	$(DOCKER_COMPOSE) exec backend bundle exec rails db:migrate
	$(DOCKER_COMPOSE) exec backend bundle exec rails db:seed
	@echo "✅ Database setup completed!"

# Pull repositories
pull:
	@echo "📥 Cloning Gwen repositories..."
	@echo ""
	@echo "📁 Creating src directory if it doesn't exist..."
	@mkdir -p src
	@echo ""
	@echo "🔧 Cloning backend repository..."
	@if [ ! -d "src/backend" ]; then \
		git clone http://10.99.100.1/gwen/gwen-backend.git src/backend; \
		echo "✅ Backend repository cloned successfully!"; \
	else \
		echo "⚠️  Backend repository already exists, skipping..."; \
	fi
	@echo ""
	@echo "🎨 Cloning frontend repository..."
	@if [ ! -d "src/frontend" ]; then \
		git clone http://10.99.100.1/gwen/gwen-frontend.git src/frontend; \
		echo "✅ Frontend repository cloned successfully!"; \
	else \
		echo "⚠️  Frontend repository already exists, skipping..."; \
	fi
	@echo ""
	@echo "🎉 All repositories ready!"
	@echo "💡 Next steps:"
	@echo "  1. Run 'make dev' to start the development environment"
	@echo "  2. Run 'make health' to check service status"

# Quick commands
up: start
down: stop
rebuild: clean build start