# PatientManagementSystem

> **Production-grade microservices backend demonstrating enterprise Java architecture**

![Java 21](https://img.shields.io/badge/Java-21-orange?logo=openjdk&logoColor=white)
![Spring Boot 3.2](https://img.shields.io/badge/Spring%20Boot-3.2.5-brightgreen?logo=springboot&logoColor=white)
![Kafka KRaft](https://img.shields.io/badge/Apache%20Kafka-KRaft-black?logo=apachekafka&logoColor=white)
![gRPC](https://img.shields.io/badge/gRPC-Protobuf%203-blue?logo=grpc&logoColor=white)
![PostgreSQL 17](https://img.shields.io/badge/PostgreSQL-17-blue?logo=postgresql&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)

---

## 📌 Quick Overview

A **5-microservice healthcare platform** showcasing distributed systems mastery:

- ✅ **5 Independent Services** (patient, billing, analytics, auth, gateway)
- ✅ **3 Communication Patterns**: REST → gRPC (type-safe) → Kafka (async events)
- ✅ **JWT Authentication** with BCrypt hashing
- ✅ **Event-Driven Architecture** (loosely coupled via Kafka KRaft)
- ✅ **Docker Compose** orchestration (one-command startup)
- ✅ **Integration Tests** validating end-to-end flows
- ✅ **Production-Ready**: Error handling, logging, health checks

**Why it matters:** Demonstrates system design thinking, architectural trade-offs, and production-grade engineering patterns used at FAANG companies.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Compose Network                       │
│                                                                 │
│  REST Client → api-gateway (Port 4004)                         │
│                    ↓                                            │
│         ┌──────────┴──────────┐                                │
│         ↓                     ↓                                 │
│    auth-service         patient-service                        │
│    (JWT Issuer)         (Main API)                             │
│    Port 4005            Port 4000                              │
│    H2 + BCrypt          PostgreSQL + UUID                      │
│                              ↓                                 │
│                    ┌─────────┼────────┐                        │
│                    ↓         ↓        ↓                        │
│              gRPC Call  Kafka Pub   billing-service            │
│              (Binary)   (Events)    (gRPC Server)              │
│                              ↓                                 │
│                        analytics-service                       │
│                        (Kafka Consumer)                        │
│                        Port 4002                               │
│                                                                │
│  ┌──────────────────────────────────────────┐                 │
│  │    Apache Kafka (KRaft - No Zookeeper)   │                 │
│  │  • patient-events topic (Protobuf)       │                 │
│  │  • Kafka UI: Port 8080                   │                 │
│  └──────────────────────────────────────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔑 Key Architectural Decisions

### 1. **Microservices (not monolith)**
- Clear domain boundaries → independent scaling
- Each service owns its database
- Deploy independently without downtime

### 2. **gRPC for Sync Calls** (patient → billing)
- Contract-first design (`.proto` enforced at compile time)
- Binary encoding ~10x faster than JSON
- Type-safe service stubs prevent drift

### 3. **Kafka for Async Events** (patient → analytics)
- Fire-and-forget pattern
- Loose coupling: analytics failures don't impact registration
- Consumer can lag or scale independently
- Event replay capability for debugging

### 4. **JWT Authentication** (stateless, scalable)
- No session storage needed
- Can scale horizontally (no sticky sessions)
- Token validation at edge (api-gateway)

---

## 📊 Services at a Glance

| Service | Port | Tech | Purpose |
|---------|------|------|---------|
| **patient-service** | 4000 | REST/Spring | Core patient CRUD → triggers gRPC + Kafka |
| **auth-service** | 4005 | JWT/Spring | Stateless token issuer, BCrypt hashing |
| **billing-service** | 9001 | gRPC | Internal service for billing accounts |
| **analytics-service** | 4002 | Kafka Consumer | Async event processing (decoupled) |
| **api-gateway** | 4004 | Spring Cloud | Request routing, JWT validation, exception handling |
| **Kafka** | 9094 | KRaft Mode | Event streaming (no Zookeeper) |
| **PostgreSQL** | 5432 | Database | Patient data with ACID guarantees |

---

## 🚀 Getting Started

### Fastest Way (Docker Compose)
```bash
docker compose up --build
```

Starts all 5 services + PostgreSQL + Kafka with one command. All inter-service connectivity automatically configured.

### Local Development
```bash
# Build all modules
mvn clean install

# Start each service in different terminal (billing-service first!):
cd billing-service && mvn spring-boot:run
cd analytics-service && mvn spring-boot:run
cd auth-service && mvn spring-boot:run
cd patient-service && mvn spring-boot:run
```

### Endpoints
- **Patient API**: http://localhost:4000/api/patients
- **Swagger UI**: http://localhost:4000/swagger-ui.html
- **Kafka UI**: http://localhost:8080
- **Auth Service**: http://localhost:4005/auth/login

---

## 🧪 Integration Tests

End-to-end tests validating real service interaction:

```bash
mvn clean test -f integration-tests/pom.xml
```

**Tests included:**
- ✅ JWT authentication flow (token generation, validation, expiry)
- ✅ Patient CRUD with bearer token
- ✅ gRPC call to billing-service
- ✅ Kafka event publishing

---

## 💡 Example Flow: Creating a Patient

```bash
# 1. Get JWT token
curl -X POST http://localhost:4005/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'

# 2. Create patient (triggers gRPC + Kafka)
curl -X POST http://localhost:4000/api/patients \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","dateOfBirth":"1990-01-15"}'
```

**What happens internally:**
1. API Gateway validates JWT → routes to patient-service
2. patient-service saves to PostgreSQL
3. **Synchronous gRPC call**: patient-service → billing-service
4. **Asynchronous Kafka publish**: PatientEvent topic
5. analytics-service consumes event asynchronously
6. Response returned immediately (analytics handles async)

**Demonstrates:** Synchronous vs async trade-offs, eventual consistency, service orchestration.

---

## 🛠️ Tech Stack Rationale

| Component | Why |
|-----------|-----|
| **Java 21** | Latest LTS with modern features (records, sealed classes) |
| **Spring Boot 3.2** | Industry standard, battle-tested ecosystem |
| **Spring Data JPA** | Reduces boilerplate, enables domain-driven design |
| **PostgreSQL 17** | ACID guarantees for patient data consistency |
| **Apache Kafka (KRaft)** | Distributed event log, 3.x production best practice (no Zookeeper) |
| **gRPC + Protobuf** | Type-safe RPC, binary encoding, contract-first design |
| **Spring Security + JJWT** | Standards-based auth, token management |
| **Docker + Compose** | Reproducible deployments, local dev mirrors production |
| **JUnit 5 + REST-Assured** | Modern testing framework, HTTP testing fluency |

---

## 🏆 Design Patterns Implemented

- **Repository Pattern** → Data access abstraction
- **Service Layer** → Business logic isolation
- **DTO Pattern** → API contracts separate from entities
- **Global Exception Handler** → Centralized error responses
- **Validation Groups** → Conditional validation (POST vs PUT)
- **Kafka Producer/Consumer** → Event-driven communication
- **API Gateway** → Single entry point, cross-cutting concerns
- **gRPC Stubs** → Type-safe inter-service calls

---

## 🔐 Security Practices

- ✅ **JWT Tokens** (stateless, scalable)
- ✅ **BCrypt Hashing** (salt-based, never plaintext passwords)
- ✅ **Spring Security** (framework-wide authorization)
- ✅ **Input Validation** (Jakarta Bean Validation prevents injection)
- ✅ **API Gateway** (centralized authentication at edge)
- ✅ **HTTPS-Ready** (easily extensible with TLS)

---

## 📈 What This Demonstrates

### For Senior Backend Roles
- ✅ System design (5 services, multiple communication patterns)
- ✅ Distributed systems thinking (eventual consistency, trade-offs)
- ✅ Production readiness (Docker, logging, error handling, tests)
- ✅ Architectural decision-making (gRPC vs REST vs Kafka - why each?)

### For Interview Discussions
1. **"Explain your architecture"**
   - 5 microservices with clear responsibilities
   - REST for external clients, gRPC for internal, Kafka for events
   - Why each pattern fits its use case

2. **"How would you scale this?"**
   - Each service scales independently
   - Kafka naturally handles consumer scaling
   - Stateless JWT auth enables horizontal scaling

3. **"What's production-ready about this?"**
   - Docker containerization with multi-stage builds
   - Proper error handling and logging
   - Integration tests validating deployment
   - Health checks and resource limits

4. **"What would you add next?"**
   - Circuit breakers (Resilience4j)
   - Distributed tracing (Jaeger)
   - Prometheus metrics
   - Kubernetes manifests
   - Database migrations (Flyway)

---

## 📂 Project Structure

```
PatientManagementSystem/
├── patient-service/          # REST API (port 4000)
│   ├── src/main/controller/  # REST endpoints
│   ├── src/main/service/     # Business logic
│   ├── src/main/grpc/        # gRPC client
│   └── src/main/kafka/       # Kafka producer
│
├── auth-service/             # JWT issuer (port 4005)
│   ├── src/main/controller/  # Auth endpoints
│   ├── src/main/util/        # JwtUtil, BCrypt
│   └── src/main/resources/   # H2 seed data
│
├── billing-service/          # gRPC server (port 9001)
│   ├── src/main/grpc/        # gRPC service impl
│   └── src/proto/            # billing_service.proto
│
├── analytics-service/        # Kafka consumer (port 4002)
│   ├── src/main/kafka/       # Kafka listener
│   └── src/proto/            # patient_event.proto
│
├── api-gateway/              # API Gateway (port 4004)
│   ├── src/main/filter/      # JWT validation filter
│   └── src/main/exception/   # Global error handling
│
├── integration-tests/        # End-to-end tests
│   └── src/test/java/        # AuthIntegrationTest, PatientIntegrationTest
│
├── docker-compose.yml        # Full stack orchestration
└── pom.xml                   # Parent POM (shared versions)
```

---

## ✨ Next Steps

### To Run Locally
```bash
docker compose up --build
```

### To Test
```bash
mvn clean test
```

### To Explore Code
- **REST API patterns**: `patient-service/src/main/controller/`
- **gRPC implementation**: `billing-service/src/main/grpc/`
- **Kafka integration**: `patient-service/src/main/kafka/`
- **Security**: `auth-service/src/main/util/JwtUtil.java`
- **Tests**: `integration-tests/src/test/java/`

---

## 🎓 Learning Resources

- [System Design Interview Prep](https://www.interviewbit.com/courses/system-design-interview/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [gRPC Java Guide](https://grpc.io/docs/languages/java/)
- [Spring Boot Best Practices](https://spring.io/guides)

---

**Built to showcase enterprise engineering excellence for career growth.** 🚀

*Created: March 2026 | Status: Production-Ready*
