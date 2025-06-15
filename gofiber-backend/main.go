package main

import (
	"database/sql"
	"log"
	"os"
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	_ "github.com/go-sql-driver/mysql"
)

type Record struct {
	ID        int    `json:"id"`
	Name      string `json:"name"`
	Value     string `json:"value"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

type User struct {
	ID        int    `json:"id"`
	Username  string `json:"username"`
	Email     string `json:"email"`
	CreatedAt string `json:"created_at"`
}

type APIKey struct {
	ID       int    `json:"id"`
	KeyName  string `json:"key_name"`
	APIKey   string `json:"api_key"`
	UserID   int    `json:"user_id"`
	IsActive bool   `json:"is_active"`
}

var db *sql.DB

func main() {
	// Initialize database connection
	initDB()
	defer db.Close()

	// Create Fiber app
	app := fiber.New(fiber.Config{
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			return c.Status(code).JSON(fiber.Map{
				"error": err.Error(),
			})
		},
	})

	// Middleware
	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders: "Origin,Content-Type,Accept,Authorization,X-API-Key",
	}))

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "gofiber-backend",
		})
	})

	// API routes
	api := app.Group("/api")

	// Records endpoints
	api.Get("/data", getRecords)
	api.Post("/data", createRecord)
	api.Get("/data/:id", getRecord)
	api.Put("/data/:id", updateRecord)
	api.Delete("/data/:id", deleteRecord)

	// Users endpoints
	api.Get("/users", getUsers)
	api.Post("/users", createUser)

	// API Keys endpoints (for demonstration)
	api.Get("/apikeys", getAPIKeys)

	// Protected routes (require API key)
	protected := api.Group("/protected", validateAPIKey)
	protected.Get("/data", getRecords)
	protected.Post("/data", createRecord)

	log.Println("GoFiber backend starting on port 8080...")
	log.Fatal(app.Listen(":8080"))
}

func initDB() {
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "3306")
	dbUser := getEnv("DB_USER", "apiuser")
	dbPassword := getEnv("DB_PASSWORD", "apipassword")
	dbName := getEnv("DB_NAME", "apiapp")

	dsn := dbUser + ":" + dbPassword + "@tcp(" + dbHost + ":" + dbPort + ")/" + dbName + "?charset=utf8mb4&parseTime=True&loc=Local"

	var err error
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	if err = db.Ping(); err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	log.Println("Connected to MariaDB database")
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// API Key validation middleware
func validateAPIKey(c *fiber.Ctx) error {
	apiKey := c.Get("X-API-Key")
	if apiKey == "" {
		return c.Status(401).JSON(fiber.Map{
			"error": "API key required",
		})
	}

	// Check if API key exists and is active
	var isActive bool
	err := db.QueryRow("SELECT is_active FROM api_keys WHERE api_key = ?", apiKey).Scan(&isActive)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"error": "Invalid API key",
		})
	}

	if !isActive {
		return c.Status(401).JSON(fiber.Map{
			"error": "API key is inactive",
		})
	}

	return c.Next()
}

// Records handlers
func getRecords(c *fiber.Ctx) error {
	rows, err := db.Query("SELECT id, name, value, created_at, updated_at FROM records ORDER BY created_at DESC")
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to fetch records",
		})
	}
	defer rows.Close()

	var records []Record
	for rows.Next() {
		var record Record
		err := rows.Scan(&record.ID, &record.Name, &record.Value, &record.CreatedAt, &record.UpdatedAt)
		if err != nil {
			continue
		}
		records = append(records, record)
	}

	return c.JSON(fiber.Map{
		"data":    records,
		"count":   len(records),
		"success": true,
	})
}

func createRecord(c *fiber.Ctx) error {
	var record Record
	if err := c.BodyParser(&record); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	if record.Name == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "Name is required",
		})
	}

	result, err := db.Exec("INSERT INTO records (name, value) VALUES (?, ?)", record.Name, record.Value)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to create record",
		})
	}

	id, _ := result.LastInsertId()
	record.ID = int(id)

	return c.Status(201).JSON(fiber.Map{
		"data":    record,
		"success": true,
		"message": "Record created successfully",
	})
}

func getRecord(c *fiber.Ctx) error {
	id, err := strconv.Atoi(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Invalid record ID",
		})
	}

	var record Record
	err = db.QueryRow("SELECT id, name, value, created_at, updated_at FROM records WHERE id = ?", id).
		Scan(&record.ID, &record.Name, &record.Value, &record.CreatedAt, &record.UpdatedAt)

	if err != nil {
		if err == sql.ErrNoRows {
			return c.Status(404).JSON(fiber.Map{
				"error": "Record not found",
			})
		}
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to fetch record",
		})
	}

	return c.JSON(fiber.Map{
		"data":    record,
		"success": true,
	})
}

func updateRecord(c *fiber.Ctx) error {
	id, err := strconv.Atoi(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Invalid record ID",
		})
	}

	var record Record
	if err := c.BodyParser(&record); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	result, err := db.Exec("UPDATE records SET name = ?, value = ? WHERE id = ?", record.Name, record.Value, id)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to update record",
		})
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		return c.Status(404).JSON(fiber.Map{
			"error": "Record not found",
		})
	}

	record.ID = id
	return c.JSON(fiber.Map{
		"data":    record,
		"success": true,
		"message": "Record updated successfully",
	})
}

func deleteRecord(c *fiber.Ctx) error {
	id, err := strconv.Atoi(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Invalid record ID",
		})
	}

	result, err := db.Exec("DELETE FROM records WHERE id = ?", id)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to delete record",
		})
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		return c.Status(404).JSON(fiber.Map{
			"error": "Record not found",
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Record deleted successfully",
	})
}

// Users handlers
func getUsers(c *fiber.Ctx) error {
	rows, err := db.Query("SELECT id, username, email, created_at FROM users ORDER BY created_at DESC")
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to fetch users",
		})
	}
	defer rows.Close()

	var users []User
	for rows.Next() {
		var user User
		err := rows.Scan(&user.ID, &user.Username, &user.Email, &user.CreatedAt)
		if err != nil {
			continue
		}
		users = append(users, user)
	}

	return c.JSON(fiber.Map{
		"data":    users,
		"count":   len(users),
		"success": true,
	})
}

func createUser(c *fiber.Ctx) error {
	var user User
	if err := c.BodyParser(&user); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	if user.Username == "" || user.Email == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "Username and email are required",
		})
	}

	result, err := db.Exec("INSERT INTO users (username, email) VALUES (?, ?)", user.Username, user.Email)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to create user",
		})
	}

	id, _ := result.LastInsertId()
	user.ID = int(id)

	return c.Status(201).JSON(fiber.Map{
		"data":    user,
		"success": true,
		"message": "User created successfully",
	})
}

// API Keys handlers
func getAPIKeys(c *fiber.Ctx) error {
	rows, err := db.Query(`
		SELECT ak.id, ak.key_name, ak.api_key, ak.user_id, ak.is_active, u.username 
		FROM api_keys ak 
		JOIN users u ON ak.user_id = u.id 
		ORDER BY ak.created_at DESC
	`)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to fetch API keys",
		})
	}
	defer rows.Close()

	var apiKeys []map[string]interface{}
	for rows.Next() {
		var apiKey APIKey
		var username string
		err := rows.Scan(&apiKey.ID, &apiKey.KeyName, &apiKey.APIKey, &apiKey.UserID, &apiKey.IsActive, &username)
		if err != nil {
			continue
		}
		
		apiKeys = append(apiKeys, map[string]interface{}{
			"id":        apiKey.ID,
			"key_name":  apiKey.KeyName,
			"api_key":   apiKey.APIKey,
			"user_id":   apiKey.UserID,
			"username":  username,
			"is_active": apiKey.IsActive,
		})
	}

	return c.JSON(fiber.Map{
		"data":    apiKeys,
		"count":   len(apiKeys),
		"success": true,
	})
}